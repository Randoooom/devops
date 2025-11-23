locals {
  postgres_bucket = var.buckets["postgres"]
  postgres_domain = "postgresql-central-rw.${kubernetes_namespace.postgres.metadata[0].name}.svc.cluster.local"

  postgres_users = [for database, user in var.postgres_databases : {
    name = user
    passwordSecret = {
      name = database
    }
    login = true
  }]
}

resource "kubernetes_namespace" "postgres" {
  metadata {
    name = "sys-postgres"
  }
}

resource "helm_release" "postgres_operator" {
  depends_on = [kubernetes_namespace.postgres]

  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = "0.26.1"

  name      = "postgres-operator"
  namespace = kubernetes_namespace.postgres.metadata[0].name

  values = [yamlencode({
    monitoring = {
      podMonitorEnabled = true
    }
  })]
}

resource "kubectl_manifest" "postgres_certificate" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "postgres-tls"
      namespace = kubernetes_namespace.postgres.metadata[0].name
    }
    spec = {
      secretName = "postgres-tls"
      issuerRef = {
        name = "cluster-authority"
        kind = "ClusterIssuer"
      }
      commonName = local.postgres_domain
      dnsNames   = [local.postgres_domain]
    }
  })
}

resource "kubernetes_secret" "postgres_backup_credentials" {
  metadata {
    name      = "postgres-backup-credentials"
    namespace = kubernetes_namespace.postgres.metadata[0].name
  }

  data = {
    id  = local.postgres_bucket.id
    key = local.postgres_bucket.key
  }
}

resource "random_password" "postgres_admin" {
  length  = 80
  special = false
}

resource "kubernetes_secret" "postgres_admin_credentials" {
  metadata {
    name      = "postgres-admin-credentials"
    namespace = kubernetes_namespace.postgres.metadata[0].name
  }

  data = {
    username = "postgres"
    password = random_password.postgres_admin.result
  }
}

resource "random_password" "postgres_user_password" {
  for_each = { for database, user in var.postgres_databases : user => user }

  special = false
  length  = 80
}

resource "kubernetes_secret" "postgres_user_credentials" {
  for_each = var.postgres_databases

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.postgres.metadata[0].name
    labels = {
      "cnpg.io/reload" = "true"
    }
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = each.value
    password = random_password.postgres_user_password[each.value].result
  }
}

resource "kubectl_manifest" "postgres_database" {
  for_each = var.postgres_databases

  yaml_body = yamlencode({
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Database"
    metadata = {
      name      = "postgresql-central-${each.key}"
      namespace = kubernetes_namespace.postgres.metadata[0].name
    }
    spec = {
      cluster = {
        name = "postgresql-central"
      }
      name  = each.key
      owner = each.value
    }
  })
}

resource "kubectl_manifest" "postgres_cluster" {
  depends_on = [helm_release.postgres_operator]

  yaml_body = yamlencode({
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"
    metadata = {
      name      = "postgresql-central"
      namespace = kubernetes_namespace.postgres.metadata[0].name
      annotations = {
        "reloader.stakater.com/auto" = "true"
      }
    }
    spec = {
      imageName = "ghcr.io/randoooom/postgis:17.3.5"

      instances             = 2
      enableSuperuserAccess = true
      superuserSecret = {
        name = kubernetes_secret.postgres_admin_credentials.metadata[0].name
      }

      bootstrap = {
        initdb = {
          postInitTemplateSQL = [
            "CREATE EXTENSION postgis;",
            "CREATE EXTENSION postgis_topology;",
            "CREATE EXTENSION fuzzystrmatch;",
            "CREATE EXTENSION postgis_tiger_geocoder;"
          ]
        }
      }

      storage = {
        size = "10Gi"
      }

      certificates = {
        serverTLSSecret = "postgres-tls"
        serverCASecret  = "postgres-tls"
      }

      backup = {
        barmanObjectStore = {
          destinationPath = "s3://${local.postgres_bucket.name}/backups/"
          endpointURL     = "https://${var.bucket_endpoint}"

          s3Credentials = {
            accessKeyId = {
              name = kubernetes_secret.postgres_backup_credentials.metadata[0].name
              key  = "id"
            }

            secretAccessKey = {
              name = kubernetes_secret.postgres_backup_credentials.metadata[0].name
              key  = "key"
            }
          }

          wal = {
            compression = "gzip"
            encryption  = "AES256"
          }

          data = {
            compression         = "gzip"
            encryption          = "AES256"
            immediateCheckpoint = false
            jobs                = 2
          }
        }

        retentionPolicy = "7d"
      }

      env = [
        {
          name  = "AWS_REQUEST_CHECKSUM_CALCULATION"
          value = "when_required"
        },
        {
          name  = "AWS_RESPONSE_CHECKSUM_CALCULATION"
          value = "when_required"
        }
      ]

      managed = {
        roles = local.postgres_users
      }

      monitoring = {
        enablePodMonitor = true
      }
    }
  })
}

resource "kubectl_manifest" "postgres_backup" {
  depends_on = [kubectl_manifest.postgres_cluster]

  yaml_body = yamlencode({
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "ScheduledBackup"
    metadata = {
      name      = "central-backup"
      namespace = kubernetes_namespace.postgres.metadata[0].name
    }
    spec = {
      schedule             = "0 0 0 * *"
      backupOwnerReference = "self"

      cluster = {
        name = "postgresql-central"
      }
    }
  })
}
