resource "helm_release" "reloader" {
  repository = "https://stakater.github.io/stakater-charts"
  chart      = "reloader"
  version    = "2.2.8"

  name      = "reloader"
  namespace = "kube-system"
}
