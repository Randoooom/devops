resource "kubectl_manifest" "ingress_certificate" {
  depends_on = [kubectl_manifest.letsencrypt]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "cilium-ingress-tls"
      namespace = kubernetes_namespace.cilium.metadata[0].name
    }
    spec = {
      secretName = "cilium-ingress-tls"
      issuerRef = {
        name = "letsencrypt"
        kind = "ClusterIssuer"
      }
      commonName = "*.${var.cluster_domain}"
      dnsNames   = ["*.${var.cluster_domain}"]
    }
  })
}
