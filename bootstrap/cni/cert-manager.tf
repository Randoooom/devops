resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "sys-cert-manager"
  }
}

resource "kubernetes_secret" "cert_manager" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = kubernetes_namespace.cert_manager.metadata[0].name
  }

  data = {
    token = var.cloudflare_api_token
  }
}

resource "helm_release" "cert_manager" {
  depends_on = [kubernetes_namespace.cert_manager]

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.18.1"

  namespace = "sys-cert-manager"
  name      = "cert-manager"

  values = [yamlencode({
    crds = {
      enabled = true
    }
    prometheus = {
      enabled = true
      servicemonitor = {
        enabled = true
      }
    }
  })]
}

resource "kubectl_manifest" "letsencrypt" {
  depends_on = [helm_release.cert_manager]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt"
    }
    spec = {
      acme = {
        email  = var.acme_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "acme-issuer-account-key"
        }
        solvers = [
          {
            dns01 = {
              cloudflare = {
                apiTokenSecretRef = {
                  name = "cloudflare-api-token"
                  key  = "token"
                }
              }
            }
          }
        ]
      }
    }
  })
}
