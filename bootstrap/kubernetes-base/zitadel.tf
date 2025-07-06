locals {
  zitadel_database = var.postgres_databases.zitadel
}

resource "kubernetes_namespace" "zitadel" {
  metadata {
    name = "sys-zitadel"
  }
}

resource "random_password" "zitadel_admin" {
  length  = 40
  special = true
}

resource "random_password" "zitadel_masterkey" {
  length  = 32
  special = false
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
      password: ${local.zitadel_database.password}
    Admin:
      password: ${var.postgres_admin_password}
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
  depends_on = [kubernetes_secret.zitadel_masterkey]

  repository = "https://charts.zitadel.com"
  chart      = "zitadel"
  version    = "8.13.4"

  name          = "zitadel"
  namespace     = kubernetes_namespace.zitadel.metadata[0].name
  wait_for_jobs = true
  wait          = true

  values = [
    yamlencode({
      extraVolumes      = [var.ca_volume]
      extraVolumeMounts = [var.ca_volume_mount]

      replicaCount = 2

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
              Host     = var.postgres_host
              Port     = 5432
              Database = "zitadel"

              User = {
                Username = local.zitadel_database.username
                SSL = {
                  Mode = "require"
                }
              }

              Admin = {
                Username = "postgres"
                SSL = {
                  Mode = "require"
                }
              }
            }
          }
        }
      }
    })
  ]
}

resource "kubectl_manifest" "zitadel_route" {
  depends_on = [helm_release.zitadel]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GRPCRoute"
    metadata = {
      name      = "zitadel"
      namespace = kubernetes_namespace.zitadel.metadata[0].name
      annotations = {
        "external-dns.alpha.kubernetes.io/target" = var.loadbalancer_ip
      }
    }
    spec = {
      parentRefs = [
        {
          name        = "cilium"
          sectionName = "https-public"
          namespace   = "default"
        }
      ]
      hostnames = ["secure.${var.public_domain}"]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = "zitadel"
              port = 8080
            }
          ]
        }
      ]
    }
  })
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
