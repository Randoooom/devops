locals {
  credentials_given = var.client_secret != null && var.client_secret != null
}

resource "kubernetes_secret" "this" {
  depends_on = [module.entra]

  metadata {
    name      = "${var.route}-oidc"
    namespace = var.namespace
  }

  data = {
    client-secret = local.credentials_given ? var.client_secret : values(module.entra[0].application_credentials)[0].client_secret
  }
}

resource "kubectl_manifest" "this" {
  depends_on = [kubernetes_secret.this]

  yaml_body = yamlencode({
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "SecurityPolicy"
    metadata = {
      name      = "${var.route}-oidc"
      namespace = var.namespace
    }
    spec = {
      targetRefs = [
        {
          group = "gateway.networking.k8s.io"
          kind  = "HTTPRoute"
          name  = var.route
        }
      ]

      oidc = {
        provider = {
          issuer = (local.credentials_given && var.issuer != null) ? var.issuer : module.entra[0].oidc_url
        }
        clientID = local.credentials_given ? var.client_id : values(module.entra[0].application_credentials)[0].client_id
        clientSecret = {
          name = "${var.route}-oidc"
        }
        redirectURL = "https://${var.hostname}/envoy/callback"
        logoutPath  = "/envoy/logout"
      }
    }
  })
}
