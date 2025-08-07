resource "helm_release" "reloader" {
  repository = "https://stakater.github.io/stakater-charts"
  chart      = "reloader"
  version    = "2.2.0"

  name      = "reloader"
  namespace = "kube-system"
}
