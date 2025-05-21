locals {
  internalIngress = "internal"
  ingress         = "nginx"
}

resource "kubernetes_namespace" "ingress" {
  metadata {
    name = "sys-ingress-nginx"
  }
}

resource "random_password" "oauth2_proxy_cookie_secret" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "oauth2_proxy" {
  metadata {
    name      = "oauth2-proxy"
    namespace = kubernetes_namespace.ingress.metadata[0].name
  }

  data = {
    cookie-secret = random_password.oauth2_proxy_cookie_secret.result
    client-id     = module.zitadel.oauth2_proxy_client_id
    client-secret = module.zitadel.oauth2_proxy_client_secret
  }
}

resource "helm_release" "oauth2_proxy" {
  depends_on = [kubernetes_secret.oauth2_proxy]

  repository = "https://oauth2-proxy.github.io/manifests"
  chart      = "oauth2-proxy"
  version    = "7.8.1"

  namespace = kubernetes_namespace.ingress.metadata[0].name
  name      = "oauth2-proxy"

  values = [yamlencode({
    config = {
      existingSecret = "oauth2-proxy"
      configFile     = <<EOF
provider = "oidc"
redirect_url = "https://secure.${var.cluster_domain}/oauth2/callback"
oidc_issuer_url = "https://${var.zitadel_host}"
email_domains = ["*"]
cookie_domains = [".${var.cluster_domain}"]
whitelist_domains = [".${var.cluster_domain}"]
user_id_claim = "sub"
provider_display_name = "ZITADEL"
pass_access_token = true
set_xauthrequest = true
EOF
    }
    metrics = {
      serviceMonitor = {
        enabled = true
      }
    }
    ingress = {
      enabled   = true
      hosts     = ["secure.${var.cluster_domain}"]
      className = "nginx"
      path      = "/oauth2"
    }
  })]
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
  depends_on = [kubernetes_namespace.ingress, helm_release.oauth2_proxy, kubectl_manifest.ingress_certificate]
  for_each   = { for i, data in local.ingresses : i => data }

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.3"

  namespace = kubernetes_namespace.ingress.metadata[0].name
  name      = each.value.name

  values = [yamlencode({
    controller = {
      config = {
        use-gzip            = true
        otlp-collector-host = "alloy.sys-monitoring.svc.cluster.local"
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
        default-ssl-certificate = "ingress-nginx/ingress-tls"
        enable-ssl-passthrough  = true
      }
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }
    }
  })]
}
