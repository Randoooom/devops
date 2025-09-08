resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = "sys-external-dns"
  }
}

resource "kubernetes_secret" "external_dns" {
  depends_on = [kubernetes_namespace.external_dns]

  metadata {
    name      = "cloudflare-api-token"
    namespace = "sys-external-dns"
  }

  data = {
    token = var.cloudflare_api_token
  }
}

resource "helm_release" "external_dns" {
  depends_on = [kubernetes_namespace.external_dns]

  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.18.0"

  namespace = "sys-external-dns"
  name      = "external-dns"

  values = [yamlencode({
    provider = {
      name = "cloudflare"
    }

    policy = "sync"

    serviceMonitor = {
      enabled = true
    }

    env = [
      {
        name : "CF_API_TOKEN"
        valueFrom = {
          secretKeyRef = {
            name : "cloudflare-api-token"
            key = "token"
          }
        }
      }
    ]

    rbac = {
      additionalPermissions = [
        {
          apiGroups = ["gateway.networking.k8s.io"]
          resources = ["gateways", "httproutes", "grpcroutes", "tlsroutes", "tcproutes", "udproutes"]
          verbs     = ["get", "watch", "list"]
        },
        {
          apiGroups = [""]
          resources = ["namespaces"]
          verbs     = ["get", "watch", "list"]
        }
      ]
    }

    extraArgs = ["--publish-internal-services", "--source=gateway-httproute", "--source=gateway-grpcroute"]
  })]
}
