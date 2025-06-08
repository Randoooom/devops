locals {
  postgres_bucket = var.buckets["postgres"]
  postgres_domain = "postgres.${var.cluster_domain}"

  postgres_users = {
    "forgejo.forgejo"                = ["CREATEDB"]
    "sys-zitadel.zitadel"            = ["CREATEDB"]
    "feedback-fusion.feedbackfusion" = ["CREATEDB"]
  }
  postgres_databases = { for user, _ in local.postgres_users : split(".", user)[1] => user }
}

resource "kubernetes_namespace" "postgres" {
  metadata {
    name = "sys-postgres"
  }
}

resource "kubernetes_secret" "postgres_s3" {
  metadata {
    name      = "postgres-s3"
    namespace = kubernetes_namespace.postgres.metadata[0].name
  }

  data = {
    AWS_ACCESS_KEY_ID     = local.postgres_bucket.id
    AWS_SECRET_ACCESS_KEY = local.postgres_bucket.key
  }
}

resource "helm_release" "postgres" {
  depends_on = [kubernetes_namespace.postgres]

  repository = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator"
  chart      = "postgres-operator"
  version    = "1.14.0"

  name      = "postgres-operator"
  namespace = kubernetes_namespace.postgres.metadata[0].name

  wait          = true
  wait_for_jobs = true

  values = [yamlencode({
    configPatroni = {
      enable_patroni_failsafe_mode = true
    }

    configKubernetes = {
      enable_cross_namespace_secret = true
    }

    configLogicalBackup = {
      logical_backup_docker_image               = "ghcr.io/zalando/postgres-operator/logical-backup:v1.14.0"
      logical_backup_s3_bucket                  = local.postgres_bucket.name
      logical_backup_s3_endpoint                = "https://${var.bucket_endpoint}"
      logical_backup_s3_retention_time          = "7 days"
      logical_backup_schedule                   = "0 0 * * *"
      logical_backup_cronjob_environment_secret = kubernetes_secret.postgres_s3.metadata[0].name
    }
  })]
}

resource "kubectl_manifest" "postgres_certificate" {
  depends_on = [kubectl_manifest.letsencrypt, kubernetes_namespace.postgres]

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
        name = "letsencrypt"
        kind = "ClusterIssuer"
      }
      commonName = local.postgres_domain
      dnsNames   = [local.postgres_domain]
    }
  })
}

resource "kubectl_manifest" "postgres" {
  depends_on = [kubectl_manifest.postgres_certificate]

  yaml_body = yamlencode({
    apiVersion = "acid.zalan.do/v1"
    kind       = "postgresql"
    metadata = {
      name      = "postgresql"
      namespace = kubernetes_namespace.postgres.metadata[0].name
    }
    spec = {
      spiloFSGroup = 103
      teamId       = "acid"
      postgresql = {
        version = "17"
      }
      enableLogicalBackup = true
      masterServiceAnnotations = {
        "external-dns.alpha.kubernetes.io/hostname" = local.postgres_domain
      }
      numberOfInstances = 2
      volume = {
        size = "2Gi"
      }
      tls = {
        secretName = "postgres-tls"
      }
      users     = local.postgres_users
      databases = local.postgres_databases
    }
  })
}
