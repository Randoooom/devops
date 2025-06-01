resource "kubernetes_namespace" "forgejo" {
  metadata {
    name = "forgejo"
  }
}

resource "random_password" "redis_password" {
  length  = 40
  special = false
}

resource "kubernetes_secret" "redis_password" {
  metadata {
    name      = "forgejo-redis-credentials"
    namespace = kubernetes_namespace.forgejo.metadata[0].name
  }

  data = {
    password = random_password.redis_password.result
  }
}

resource "random_password" "forgejo_postgres_admin" {
  length  = 40
  special = false
}

resource "random_password" "forgejo_postgres_gitea" {
  length  = 40
  special = false
}

resource "random_password" "forgejo_postgres_replication" {
  length  = 40
  special = false
}

resource "kubernetes_secret" "forgejo_postgres" {
  metadata {
    name      = "forgejo-postgres-credentials"
    namespace = kubernetes_namespace.forgejo.metadata[0].name
  }

  data = {
    password             = random_password.forgejo_postgres_gitea.result
    postgres-password    = random_password.forgejo_postgres_admin.result
    replication-password = random_password.forgejo_postgres_replication.result
  }
}

resource "kubernetes_secret" "forgejo_config" {
  depends_on = [kubernetes_namespace.forgejo]

  metadata {
    name      = "forgejo-config"
    namespace = kubernetes_namespace.forgejo.metadata[0].name
  }

  data = {
    database   = <<EOF
DB_TYPE=postgres
HOST=forgejo-postgresql
NAME=gitea
USER=gitea
PASSWD=${random_password.forgejo_postgres_gitea.result}
SCHEMA=public
EOF
    server     = <<EOF
DOMAIN=git.${var.public_domain}
SSH_DOMAIN=ssh.git.${var.public_domain}
EOF
    storage    = <<EOF
STORAGE_TYPE=minio
MINIO_ENDPOINT=${var.bucket_endpoint}
MINIO_USE_SSL=true
MINIO_ACCESS_KEY_ID=${var.forgejo_bucket.id}
MINIO_SECRET_ACCESS_KEY=${var.forgejo_bucket.key}
MINIO_BUCKET=${var.forgejo_bucket.name}
MINIO_LOCATION=${var.region}
EOF
    queue      = <<EOF
TYPE=redis
CONN_STR=redis://:${random_password.redis_password.result}@forgejo-redis-master:6379/0
EOF
    cache      = <<EOF
ENABLED=true
ADAPTER=redis
HOST=redis://:${random_password.redis_password.result}@forgejo-redis-master:6379/0
EOF
    session    = <<EOF
PROVIDER=redis
PROVIDER_CONFIG=redis://:${random_password.redis_password.result}@forgejo-redis-master:6379/0
EOF
    service    = <<EOF
DISABLE_REGISTRATION=false
SHOW_REGISTRATION_BUTTON=false
REGISTER_EMAIL_CONFIRM=true
ENABLE_NOTIFY_MAIL=true
DEFAULT_USER_IS_RESTRICTED=true
DEFAULT_USER_VISIBILITY=limited
DEFAULT_ORG_VISIBILITY=limited
ALLOWED_USER_VISIBILITY_MODES=limited,private
ALLOW_ONLY_EXTERNAL_REGISTRATION=true
EOF
    actions    = <<EOF
DEFAULT_ACTIONS_URL=https://git.${var.public_domain}
EOF
    mailer     = <<EOF
ENABLED=true
PROTOCOL=smtp+starttls
SMTP_PORT=587
SMTP_ADDR=${var.smtp_host}
USER=${var.smtp_sender["git.${var.public_domain}"]["no-reply@git.${var.public_domain}"].username}
PASSWD="${var.smtp_sender["git.${var.public_domain}"]["no-reply@git.${var.public_domain}"].password}"
FROM=no-reply@git.${var.public_domain}
EOF
    oauth2_client = <<EOF
ENABLE_AUTO_REGISTRATION=true
EOF
  }
}

resource "random_password" "forgejo_admin" {
  length  = "40"
  special = false
}

resource "kubernetes_secret" "forgejo_admin" {
  depends_on = [kubernetes_namespace.forgejo]

  metadata {
    name      = "forgejo-admin"
    namespace = kubernetes_namespace.forgejo.metadata[0].name
  }

  data = {
    username = "forgejo-admin"
    password = random_password.forgejo_admin.result
  }
}

resource "kubernetes_secret" "forgejo_oauth" {
  depends_on = [kubernetes_namespace.forgejo]

  metadata {
    name      = "forgejo-oauth"
    namespace = kubernetes_namespace.forgejo.metadata[0].name
  }

  data = {
    key    = var.forgejo_client_id
    secret = var.forgejo_client_secret
  }
}

resource "helm_release" "forgejo" {
  depends_on = [kubernetes_namespace.forgejo, kubernetes_secret.redis_password, kubernetes_secret.forgejo_config, kubernetes_secret.forgejo_admin, kubernetes_secret.forgejo_oauth]

  chart = "oci://code.forgejo.org/forgejo-helm/forgejo"

  name      = "forgejo"
  namespace = kubernetes_namespace.forgejo.metadata[0].name

  values = [yamlencode({
    redis-cluster = {
      enabled = false
    }

    redis = {
      enabled = true

      auth = {
        existingSecret            = "forgejo-redis-credentials"
        existingSecretPasswordKey = "password"
      }

      master = {
        persistence = {
          size = "2Gi"
        }
      }
    }

    postgresql-ha = {
      enabled = false
    }

    postgresql = {
      enabled = true

      global = {
        postgresql = {
          auth = {
            existingSecret = "forgejo-postgres-credentials"
            secretKeys = {
              adminPasswordKey       = "postgres-password"
              userPasswordKey        = "password"
              replicationPasswordKey = "replication-password"
            }
          }
        }
      }

      primary = {
        persistence = {
          size = "5Gi"
        }
      }
    }

    gitea = {
      additionalConfigSources = [
        {
          secret = {
            secretName = "forgejo-config"
          }
        }
      ]

      admin = {
        existingSecret = "forgejo-admin"
        email          = var.forgejo_admin
      }

      oauth = [
        {
          name            = "Zitadel"
          provider        = "openidConnect"
          existingSecret  = "forgejo-oauth"
          autoDiscoverUrl = "https://secure.${var.public_domain}/.well-known/openid-configuration"
        }
      ]
    }

    service = {
      ssh = {
        annotations = {
          "external-dns.alpha.kubernetes.io/hostname" = "ssh.git.${var.public_domain}"
        }
      }
    }

    ingress = {
      enabled = true
      hosts = [
        {
          host = "git.${var.public_domain}"
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
          secretName = "forgejo-tls"
          hosts = [
            "git.${var.public_domain}"
          ]
        }
      ]
      annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt"
      }
      className = "nginx"
    }

    persistence = {
      enabled = true
      size    = "5Gi"
    }
  })]
}
