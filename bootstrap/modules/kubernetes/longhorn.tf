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
  version    = "1.7.2"

  namespace = "sys-longhorn"
  name      = "longhorn"

  values = [yamlencode({
    longhornUI = {
      replicas = 0
    }
    metrics = {
      serviceMonitor = {
        enabled = true
      }
    }
  })]
}
