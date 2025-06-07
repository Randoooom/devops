resource "kubernetes_namespace" "zitadel" {
  metadata {
    name = "sys-zitadel"
  }
}

resource "random_password" "zitadel_postgres_admin" {
  length  = 40
  special = false
}

resource "random_password" "zitadel_postgres_zitadel" {
  length  = 40
  special = false
}

resource "random_password" "zitadel_postgres_replication" {
  length  = 40
  special = false
}

resource "random_password" "zitadel_admin" {
  length  = 40
  special = true
}

resource "random_password" "zitadel_masterkey" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "zitadel_postgres" {
  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace.zitadel.metadata[0].name
  }

  data = {
    password             = random_password.zitadel_postgres_zitadel.result
    postgres-password    = random_password.zitadel_postgres_admin.result
    replication-password = random_password.zitadel_postgres_replication.result
  }
}

resource "helm_release" "zitadel_postgres" {
  depends_on = [kubernetes_namespace.zitadel, helm_release.longhorn, kubernetes_secret.zitadel_postgres]

  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "16.7.10"

  name      = "zitadel-postgres"
  namespace = kubernetes_namespace.zitadel.metadata[0].name

  values = [
    yamlencode({
      global = {
        postgresql = {
          auth = {
            username       = "zitadel"
            database       = "zitadel"
            existingSecret = "postgres-credentials"
          }
        }
      }
      primary = {
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
    })
  ]
}

resource "kubernetes_secret" "zitadel" {
  metadata {
    name      = "zitadel-config"
    namespace = kubernetes_namespace.zitadel.metadata[0].name
  }

  data = {
    config-yaml = <<EOF
Database:
  postgres:
    User:
      password: ${random_password.zitadel_postgres_zitadel.result} 
    Admin:
      password: ${random_password.zitadel_postgres_admin.result} 
FirstInstance:
  InstanceName: ${var.cluster_name}
  Org:
    Name: ${var.cluster_name} 
    Human:
      Username: admin
      Email:
        Address: ${var.zitadel_admin_mail} 
      Password: "${random_password.zitadel_admin.result}"
      PasswordChangeRequired: false
  SMTPConfiguration:
    SMTP:
      Host: ${var.zitadel_smtp_host} 
      User: ${var.zitadel_smtp_username} 
      Password: "${var.zitadel_smtp_password}"
    TLS: ${var.zitadel_smtp_tls} 
    From: ${var.zitadel_smtp_sender}
    FromName: ${var.zitadel_smtp_sender}
EOF
  }
}

resource "kubernetes_secret" "zitadel_masterkey" {
  metadata {
    name      = "zitadel-masterkey"
    namespace = kubernetes_namespace.zitadel.metadata[0].name
  }

  data = {
    masterkey = random_password.zitadel_masterkey.result
  }
}

resource "helm_release" "zitadel" {
  depends_on = [helm_release.zitadel_postgres, kubernetes_secret.zitadel_masterkey]

  repository = "https://charts.zitadel.com"
  chart      = "zitadel"
  version    = "8.13.3"

  name          = "zitadel"
  namespace     = kubernetes_namespace.zitadel.metadata[0].name
  wait_for_jobs = true
  wait          = true

  values = [
    yamlencode({
      ingress = {
        enabled   = true
        className = local.ingress
        annotations = {
          "cert-manager.io/cluster-issuer"                    = "letsencrypt"
          "nginx.ingress.kubernetes.io/backend-protocol"      = "GRPC"
          "nginx.ingress.kubernetes.io/configuration-snippet" = <<EOF
grpc_set_header Host $http_host;
EOF
        }
        hosts = [
          {
            host = "secure.${var.public_domain}"
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
              }
            ]
          }
        ]
        tls = [
          {
            hosts      = ["secure.${var.public_domain}"]
            secretName = "zitadel-tls"
          }
        ]
      }

      replicaCount = 1

      zitadel = {
        masterkeySecretName = "zitadel-masterkey"
        configSecretName    = "zitadel-config"

        configmapConfig = {
          FirstInstance = {
            Org = {
              Machine = {
                Machine = {
                  Username = "terraform"
                  Name     = "terraform"
                }
                MachineKey = {
                  Type           = "1"
                  ExpirationData = "2030-01-01T00:00:00Z"
                }
              }
            }
          }

          ExternalDomain = "secure.${var.public_domain}"
          TLS = {
            enabled = false
          }

          Database = {
            Postgres = {
              Host     = "zitadel-postgres-postgresql"
              Port     = 5432
              Database = "zitadel"
              User = {
                Username = "zitadel"
                SSL = {
                  Mode = "disable"
                }
              }
              Admin = {
                Username = "postgres"
                SSL = {
                  Mode = "disable"
                }
              }
            }
          }
        }
      }
    })
  ]
}

resource "null_resource" "wait_for_zitadel" {
  depends_on = [helm_release.zitadel]

  provisioner "local-exec" {
    command = <<EOT
    for i in {1..60}; do
      if curl -o /dev/null -s --fail https://secure.${var.public_domain}/debug/ready; then
        exit 0
      fi
      sleep 10
    done
    exit 1
    EOT
  }
}
