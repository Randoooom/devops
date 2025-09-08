resource "kubernetes_namespace" "longhorn" {
  metadata {
    name = "sys-longhorn"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "longhorn" {
  depends_on = [kubernetes_namespace.longhorn]

  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = "1.9.1"

  namespace = "sys-longhorn"
  name      = "longhorn"

  values = [yamlencode({
    longhornUI = {
      replicas = 1
    }
  })]
}

resource "kubectl_manifest" "longhorn_route" {
  depends_on = [helm_release.longhorn]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "longhorn"
      namespace = kubernetes_namespace.longhorn.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name        = "private"
          sectionName = "https"
          namespace   = "default"
        }
      ]
      hostnames = ["longhorn.internal.${var.cluster_domain}"]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = "longhorn-frontend"
              port = 80
            }
          ]
        }
      ]
    }
  })
}

module "longhorn-oidc" {
  source = "${var.module_path}/envoy-oidc-security-policy"

  cluster_name = var.cluster_name
  route        = "longhorn"
  hostname     = "longhorn.internal.${var.cluster_domain}"
  namespace    = kubernetes_namespace.longhorn.metadata[0].name
}
