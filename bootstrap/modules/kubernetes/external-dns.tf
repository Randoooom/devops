resource "kubernetes_namespace" "external_dns" {
  depends_on = [helm_release.linkerd]

  metadata {
    name = "sys-external-dns"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }

    annotations = {
      "linkerd.io/inject" = "enabled"
    }
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
  version    = "1.15.0"

  namespace = "sys-external-dns"
  name      = "external-dns"

  values = [yamlencode({
    provider = {
      name = "cloudflare"
    }

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

    sources   = ["service"]
    extraArgs = ["--exclude-target-net=${var.public_subnet_cidr}"]
  })]
}
