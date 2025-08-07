resource "kubernetes_namespace" "longhorn" {
  metadata {
    name = "sys-longhorn"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "kubernetes_secret" "longhorn_backup_credentials" {
  metadata {
    name      = "longhorn-backup-credentials"
    namespace = kubernetes_namespace.longhorn.metadata[0].name
  }

  data = {
    AWS_ACCESS_KEY_ID     = var.backup_bucket_access_key_id
    AWS_SECRET_ACCESS_KEY = var.backup_bucket_secret_access_key
    AWS_ENDPOINTS         = var.backup_bucket_endpoint
    # VIRTUAL_HOSTED_STYLE  = true
  }
}

resource "helm_release" "longhorn" {
  depends_on = [kubernetes_namespace.longhorn, kubernetes_secret.longhorn_backup_credentials]

  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = "1.9.1"

  namespace = "sys-longhorn"
  name      = "longhorn"

  values = [yamlencode({
    longhornUI = {
      replicas = 1
    }

    ingress = {
      enabled          = true
      ingressClassName = "internal"
      host             = "longhorn.internal.${var.cluster_domain}"
      annotations = {
        "nginx.ingress.kubernetes.io/auth-response-headers"   = "Authorization"
        "nginx.ingress.kubernetes.io/auth-signin"             = "https://secure.${var.cluster_domain}/oauth2/start?rd=$scheme://$host$escaped_request_uri"
        "nginx.ingress.kubernetes.io/auth-url"                = "https://secure.${var.cluster_domain}/oauth2/auth"
        "external-dns.alpha.kubernetes.io/cloudflare-proxied" = "false"
      }
    }

    defaultBackupStore = {
      backupTarget                 = "s3://${var.backup_bucket_name}@default/${var.cluster_name}"
      backupTargetCredentialSecret = kubernetes_secret.longhorn_backup_credentials.metadata[0].name
    }
  })]
}

resource "kubectl_manifest" "longhorn_snapshots" {
  yaml_body = yamlencode({
    apiVersion = "longhorn.io/v1beta2"
    kind       = "RecurringJob"
    metadata = {
      name      = "longhorn-snapshot"
      namespace = kubernetes_namespace.longhorn.metadata[0].name
    }
    spec = {
      cron        = "0 0 * * *"
      task        = "snapshot"
      groups      = ["default"]
      retain      = 3
      concurrency = 2
    }
  })
}

resource "kubectl_manifest" "longhorn_backups" {
  yaml_body = yamlencode({
    apiVersion = "longhorn.io/v1beta2"
    kind       = "RecurringJob"
    metadata = {
      name      = "longhorn-backup"
      namespace = kubernetes_namespace.longhorn.metadata[0].name
    }
    spec = {
      cron        = "0 0 * * 0"
      task        = "backup"
      groups      = ["default"]
      retain      = 3
      concurrency = 2
    }
  })
}
