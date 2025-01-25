resource "kubernetes_namespace" "falco" {
  metadata {
    name = "sys-falco"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

#resource "helm_release" "falco" {
#  depends_on = [kubernetes_namespace.falco]
#
#  repository = "https://falcosecurity.github.io/charts"
#  chart      = "falco"
#  version    = "4.17.2"
#
#  namespace = "sys-falco"
#  name      = "falco"
#
#  values = [yamlencode({
#    serviceMonitor = {
#      create = true
#    }
#  })]
#}
