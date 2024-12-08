resource "kubernetes_namespace" "ingress" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "kubectl_manifest" "oauth2_proxy_secret" {
  depends_on = [kubectl_manifest.secret_store]

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "oauth2-proxy"
      namespace = "ingress-nginx"
    },
    spec = {
      secretStoreRef = {
        kind = "ClusterSecretStore"
        name = "oracle"
      }
      target = {
        name           = "oauth2-proxy"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "cookie-secret"
          remoteRef = {
            key = "oauth2-proxy-cookie-secret"
          }
        },
        {
          secretKey = "client-secret"
          remoteRef = {
            key = "oauth2-proxy-client-secret"
          }
        },
        {
          secretKey = "client-id"
          remoteRef = {
            key = "oauth2-proxy-client-id"
          }
        }
      ]
    }
  })
}

resource "helm_release" "oauth2_proxy" {
  depends_on = [kubectl_manifest.oauth2_proxy_secret]

  repository = "https://oauth2-proxy.github.io/manifests"
  chart      = "oauth2-proxy"
  version    = "7.8.1"

  namespace = "ingress-nginx"
  name      = "oauth2-proxy"

  values = [yamlencode({
    config = {
      existingSecret = "oauth2-proxy"
      configFile     = <<EOF
provider = "oidc"
redirect_url = "https://auth.${var.cluster_domain}/oauth2/callback"
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
      hosts     = ["auth.${var.cluster_domain}"]
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
      namespace = "ingress-nginx"
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
  ingress = [
    {
      name      = "ingress-nginx"
      className = "nginx"
      internal  = false
      annotations = {
        "service.beta.kubernetes.io/oci-load-balancer-subnet1" = var.public_subnet
        "oci.oraclecloud.com/load-balancer-type"               = "lb"
        "service.beta.kubernetes.io/oci-load-balancer-shape"   = "10Mbps"
        "external-dns.alpha.kubernetes.io/hostname"            = "*.${var.cluster_domain}"
      }
    },
    {
      name      = "internal-ingress-nginx"
      className = "internal"
      internal  = true
      annotations = {
        "external-dns.alpha.kubernetes.io/internal-hostname" = "*.internal.${var.cluster_domain}"
      }
    }
  ]
}

resource "helm_release" "ingress" {
  depends_on = [kubernetes_namespace.ingress, helm_release.oauth2_proxy, kubectl_manifest.ingress_certificate]
  for_each   = { for i, data in local.ingress : i => data }

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.3"

  namespace = "ingress-nginx"
  name      = each.value.name

  values = [yamlencode({
    controller = {
      config = {
        use-gzip = true
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
