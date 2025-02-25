resource "kubernetes_namespace" "external_secrets" {
  depends_on = [helm_release.linkerd]

  metadata {
    name = "sys-external-secrets"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }

    annotations = {
      "linkerd.io/inject" = "enabled"
    }
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

resource "kubernetes_manifest" "secrets" {
  for_each = fileset("${path.module}/secrets", "**/*.yaml")

  manifest = yamldecode(file("${path.module}/secrets/${each.value}"))
}
