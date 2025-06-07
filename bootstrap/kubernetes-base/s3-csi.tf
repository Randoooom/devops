resource "kubernetes_namespace" "s3" {
  metadata {
    name = "sys-s3"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "random_password" "juicefs_redis_password" {
  special = false
  length  = 40
}

resource "kubernetes_secret" "juicefs_redis_credentials" {
  metadata {
    name      = "juicefs-redis-credentials"
    namespace = kubernetes_namespace.s3.metadata[0].name
  }

  data = {
    password = random_password.juicefs_redis_password.result
  }
}

resource "helm_release" "s3_redis" {
  depends_on = [kubernetes_namespace.s3, kubernetes_secret.juicefs_redis_credentials]

  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "redis"
  version    = "21.1.11"

  name      = "juicefs-redis"
  namespace = kubernetes_namespace.s3.metadata[0].name

  values = [yamlencode({
    architecture = "standalone"

    auth = {
      existingSecret            = "juicefs-redis-credentials"
      existingSecretPasswordKey = "password"
    }

    master = {
      count = 1

      persistence = {
        size = "4Gi"
      }

      resources = {
        requests = {
          cpu               = "40m"
          memory            = "60Mi"
          ephemeral-storage = "50Mi"
        }
        limits = {
          cpu               = "150m"
          memory            = "200Mi"
          ephemeral-storage = "2Gi"
        }
      }
    }
  })]
}

resource "helm_release" "s3" {
  depends_on = [kubernetes_namespace.s3]

  repository = "https://juicedata.github.io/charts"
  chart      = "juicefs-csi-driver"
  version    = "0.28.1"

  name      = "juicefs"
  namespace = kubernetes_namespace.s3.metadata[0].name

  values = [yamlencode({
    mountMode = "process"

    sidecars = {
      livenessProbeImage = {
        repository = "registry.k8s.io/sig-storage/livenessprobe"
        tag        = "v2.14.0"
      }
      csiProvisionerImage = {
        repository = "registry.k8s.io/sig-storage/csi-provisioner"
        tag        = "v2.2.2"
      }
      nodeDriverRegistrarImage = {
        repository = "registry.k8s.io/sig-storage/csi-node-driver-registrar"
        tag        = "v2.14.0"
      }
      csiResizerImage = {
        repository = "registry.k8s.io/sig-storage/csi-resizer"
        tag        = "v1.8.0"
      }
    }

    controller = {
      resources = {
        requests = {
          cpu = "20m"
        }

        limits = {
          cpu = "100m"
        }
      }
    }

    dashboard = {
      resources = {
        requests = {
          cpu = "20m"
        }

        limits = {
          cpu = "100m"
        }
      }
    }

    node = {
      envs = [
        {
          name = "JUICEFS_MOUNT_NAMESPACE"
          valueFrom = {
            fieldRef = {
              fieldPath = "metadata.namespace"
            }
          }
        }
      ]

      resources = {
        requests = {
          cpu = "20m"
        }

        limits = {
          cpu = "100m"
        }
      }
    }

  })]
}

resource "kubernetes_secret" "juicefs_s3_credentials" {
  count = contains(keys(var.buckets), "${var.cluster_name}-csi") ? 1 : 0

  metadata {
    name      = "juicefs-s3-credentials"
    namespace = kubernetes_namespace.s3.metadata[0].name
  }

  data = {
    name       = "juicefs"
    metaurl    = "redis://:${random_password.juicefs_redis_password.result}@juicefs-redis-master:6379/0"
    storage    = "s3"
    bucket     = "https://${var.buckets["${var.cluster_name}-csi"].name}.${var.bucket_endpoint}"
    access-key = var.buckets["${var.cluster_name}-csi"].id
    secret-key = var.buckets["${var.cluster_name}-csi"].key
  }
}

resource "kubernetes_storage_class" "s3" {
  depends_on = [helm_release.s3]

  metadata {
    name = "s3"
  }

  storage_provisioner = "csi.juicefs.com"
  reclaim_policy      = "Retain"

  parameters = {
    "csi.storage.k8s.io/provisioner-secret-name"       = "juicefs-s3-credentials"
    "csi.storage.k8s.io/provisioner-secret-namespace"  = kubernetes_namespace.s3.metadata[0].name
    "csi.storage.k8s.io/node-publish-secret-name"      = "juicefs-s3-credentials"
    "csi.storage.k8s.io/node-publish-secret-namespace" = kubernetes_namespace.s3.metadata[0].name
  }
}
