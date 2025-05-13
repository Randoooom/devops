resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "sys-external-secrets"
  }
}

resource "helm_release" "external_secrets" {
  depends_on = [kubernetes_namespace.external_secrets]

  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.11.0"

  namespace = "sys-external-secrets"
  name      = "external-secrets"

  values = [yamlencode({
    installCRDs = true
    serviceMonitor = {
      enabled = true
    }
  })]
}

resource "kubectl_manifest" "secret_store" {
  depends_on = [helm_release.external_secrets]

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "oracle"
    }
    spec = {
      provider = {
        oracle = {
          vault  = var.vault,
          region = var.region
        }
      }
    }
  })
}

resource "kubernetes_secret" "nextcloud" {
  metadata {
    name      = "nextcloud-oci"
    namespace = "nextcloud"
  }

  data = {
    id     = var.nextcloud_access_key_id
    key    = var.nextcloud_secret_access_key
    bucket = "${var.cluster_name}-nextcloud"
    host   = "${var.bucket_namespace}.compat.objectstorage.eu-frankfurt-1.oraclecloud.com"
  }
}
