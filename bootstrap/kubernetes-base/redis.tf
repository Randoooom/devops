locals {
  redis_domain = "redis.${var.cluster_domain}"
  redis_bucket = var.buckets["redis"]

  dragonfly_manifest = {
    apiVersion = "dragonflydb.io/v1alpha1"
    kind       = "Dragonfly"
    metadata = {
      name      = "dragonfly"
      namespace = kubernetes_namespace.redis.metadata[0].name
    }
    spec = {
      authentication = {
        passwordFromSecret = {
          name = kubernetes_secret.dragonfly_password.metadata[0].name
          key  = "password"
        }
      }
      replicas = 2
      tlsSecretRef = {
        name = "dragonfly-tls"
      }
      serviceSpec = {
        annotations = {
          "external-dns.alpha.kubernetes.io/hostname" = local.redis_domain
        }
      }
      snapshot = {
        cron = "0 * * * *"
        dir  = "s3://${local.redis_bucket.name}/"
      }
      env = [
        {
          name = "AWS_ACCESS_KEY_ID"
          valueFrom = {
            secretKeyRef = {
              name = kubernetes_secret.dragonfly_s3.metadata[0].name
              key  = "id"
            }
          }
        },
        {
          name = "AWS_SECRET_ACCESS_KEY"
          valueFrom = {
            secretKeyRef = {
              name = kubernetes_secret.dragonfly_s3.metadata[0].name
              key  = "key"
            }
          }
        },
        {
          name  = "DFLY_s3_endpoint"
          value = "${var.bucket_endpoint}"
        }
      ]

    }
  }
}

resource "kubernetes_namespace" "redis" {
  metadata {
    name = "sys-redis"
  }
}

resource "random_password" "dragonfly_password" {
  special = false
  length  = 40
}

resource "kubernetes_secret" "dragonfly_password" {
  metadata {
    name      = "dragonfly-password"
    namespace = kubernetes_namespace.redis.metadata[0].name
  }

  data = {
    password = random_password.dragonfly_password.result
  }
}

resource "helm_release" "dragonfly" {
  depends_on = [kubernetes_namespace.redis]

  chart   = "oci://ghcr.io/dragonflydb/dragonfly-operator/helm/dragonfly-operator"
  version = "v1.1.11"

  name      = "dragonfly-operator"
  namespace = kubernetes_namespace.redis.metadata[0].name

  values = [yamlencode({
    serviceMonitor = {
      enabled = true
    }
  })]
}

resource "kubectl_manifest" "dragonfly_certificate" {
  depends_on = [kubectl_manifest.letsencrypt]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "dragonfly-tls"
      namespace = kubernetes_namespace.redis.metadata[0].name
    }
    spec = {
      secretName = "dragonfly-tls"
      issuerRef = {
        name = "letsencrypt"
        kind = "ClusterIssuer"
      }
      commonName = local.redis_domain
      dnsNames   = [local.redis_domain]
    }
  })
}

resource "kubernetes_secret" "dragonfly_s3" {
  depends_on = [kubernetes_namespace.redis]

  metadata {
    name      = "dragonfly-s3"
    namespace = kubernetes_namespace.redis.metadata[0].name
  }

  data = {
    id  = local.redis_bucket.id
    key = local.redis_bucket.key
  }
}

resource "null_resource" "dragonfly_dump" {
  triggers = {
    manifest = sha256(yamlencode(local.dragonfly_manifest))
  }
}

resource "kubernetes_job" "dragonfly_dump" {
  depends_on = [null_resource.dragonfly_dump]

  metadata {
    name      = "dragonfly-dump"
    namespace = kubernetes_namespace.redis.metadata[0].name
  }

  spec {
    template {
      metadata {
        labels = {
          job = "dragonfly-dump"
        }
      }

      spec {
        container {
          name  = "dragonfly-dump"
          image = "redis:7.4-alpine"
          command = [
            "sh", "-c",
            <<EOT
if redis-cli --tls -h ${local.redis_domain} PING | grep -q PONG; then
  redis-cli --tls -h ${local.redis_domain} SAVE
fi
EOT
          ]

          env {
            name = "REDISCLI_AUTH"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.dragonfly_password.metadata[0].name
                key  = "password"
              }
            }
          }
        }

        restart_policy = "Never"
      }
    }
    backoff_limit = 1
  }
}

resource "kubectl_manifest" "dragonfly" {
  depends_on = [helm_release.dragonfly, null_resource.dragonfly_dump]

  yaml_body = yamlencode(local.dragonfly_manifest)
}
