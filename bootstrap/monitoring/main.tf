resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "sys-monitoring"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}
