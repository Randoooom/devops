resource "kubernetes_namespace" "argocd" {
  depends_on = [helm_release.prometheus_operator]

  metadata {
    name = "sys-argocd"
  }
}

resource "kubectl_manifest" "argocd_zitadel" {
  depends_on = [kubectl_manifest.secret_store]

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "argocd-zitadel"
      namespace = "sys-argocd"
      labels = {
        "app.kubernetes.io/part-of" = "argocd"
      }
    },
    spec = {
      secretStoreRef = {
        kind = "ClusterSecretStore"
        name = "oracle"
      }
      target = {
        name           = "argocd-zitadel"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "client-secret"
          remoteRef = {
            key = "argocd-client-secret"
          }
        },
        {
          secretKey = "client-id"
          remoteRef = {
            key = "argocd-client-id"
          }
        }
      ]
    }
  })
}

resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd, kubectl_manifest.argocd_zitadel]

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.7.7"

  namespace = "sys-argocd"
  name      = "argocd"

  values = [yamlencode({
    global = {
      domain = "argocd.internal.${var.cluster_domain}"
    }
    configs = {
      params = {
        "server.insecure" = false
      }

      cm = {
        "oidc.config" = <<EOF
name: Zitadel
issuer: https://${var.zitadel_host}
clientID: $argocd-zitadel:client-id 
clientSecret: $argocd-zitadel:client-secret
requestedScopes:
  - openid
  - profile
  - email
  - groups
EOF
        url           = "https://argocd.internal.${var.cluster_domain}"
      }

      rbac = {
        "policy.default" = ""
        "policy.csv"     = <<EOF
g, admin, role:admin
EOF
      }
    }
    server = {
      ingress = {
        enabled          = true
        ingressClassName = "internal"
        annotations = {
          "cert-manager.io/cluster-issuer"               = "letsencrypt"
          "nginx.ingress.kubernetes.io/ssl-passthrough"  = true
          "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
        }
        tls = true
      }
    }
    dex = {
      enabled = false
    }
  })]
}
