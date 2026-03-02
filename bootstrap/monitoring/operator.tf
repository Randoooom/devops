resource "helm_release" "opentelemetry_operator" {
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-operator"
  version    = "0.106.0"

  name      = "opentelemetry-operator"
  namespace = kubernetes_namespace.monitoring.metadata[0].name
}
