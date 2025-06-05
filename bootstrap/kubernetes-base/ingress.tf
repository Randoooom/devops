locals {
  internalIngress = "internal"
  ingress         = "nginx"
}

resource "kubernetes_namespace" "ingress" {
  metadata {
    name = "sys-ingress-nginx"
  }
}

resource "kubectl_manifest" "ingress_certificate" {
  depends_on = [kubectl_manifest.letsencrypt]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "ingress-tls"
      namespace = kubernetes_namespace.ingress.metadata[0].name
    }
    spec = {
      secretName = "ingress-tls"
      issuerRef = {
        name = "letsencrypt"
        kind = "ClusterIssuer"
      }
      commonName = "*.${var.cluster_domain}"
      dnsNames   = ["*.${var.cluster_domain}", "*.internal.${var.cluster_domain}"]
    }
  })
}

locals {
  ingresses = [
    {
      name      = "ingress-nginx"
      className = local.ingress
      internal  = false
      annotations = {
        "oci-network-load-balancer.oraclecloud.com/subnet"                        = var.public_subnet
        "oci.oraclecloud.com/load-balancer-type"                                  = "nlb"
        "oci-network-load-balancer.oraclecloud.com/security-list-management-mode" = "None"
        "external-dns.alpha.kubernetes.io/hostname"                               = "*.${var.cluster_domain}"
      }
    },
    {
      name      = "internal-ingress-nginx"
      className = local.internalIngress
      internal  = true
      annotations = {
        "external-dns.alpha.kubernetes.io/internal-hostname" = "*.internal.${var.cluster_domain}"
      }
    }
  ]
}

resource "helm_release" "ingress" {
  depends_on = [kubernetes_namespace.ingress, kubectl_manifest.ingress_certificate]
  for_each   = { for i, data in local.ingresses : i => data }

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.12.3"

  namespace = kubernetes_namespace.ingress.metadata[0].name
  name      = each.value.name

  values = [yamlencode({
    controller = {
      config = {
        use-gzip               = true
        otlp-collector-host    = "alloy.sys-monitoring.svc.cluster.local"
        annotations-risk-level = "Critical"
      }
      ingressClass = each.value.className
      ingressClassResource = {
        name            = each.value.className
        controllerValue = each.value.internal ? "k8s.io/internal-ingress-nginx" : "k8s.io/nginx"
      }
      allowSnippetAnnotations = true
      service = {
        type        = each.value.internal ? "ClusterIP" : "LoadBalancer"
        annotations = each.value.annotations
      }
      extraArgs = {
        default-ssl-certificate = "sys-ingress-nginx/ingress-tls"
        enable-ssl-passthrough  = true
      }
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }
      resources = {
        requests = {
          cpu = "25m"
        }
      }
    }
  })]
}
