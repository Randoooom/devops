resource "random_password" "oauth2_proxy_cookie_secret" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "oauth2_proxy" {
  metadata {
    name      = "oauth2-proxy"
    namespace = "sys-ingress-nginx"
  }

  data = {
    cookie-secret  = random_password.oauth2_proxy_cookie_secret.result
    client-id      = var.oauth2_proxy_client_id
    client-secret  = var.oauth2_proxy_client_secret
    redis-password = var.redis_password
  }
}

resource "helm_release" "oauth2_proxy" {
  depends_on = [kubernetes_secret.oauth2_proxy]

  repository = "https://oauth2-proxy.github.io/manifests"
  chart      = "oauth2-proxy"
  version    = "7.18.0"

  namespace = "sys-ingress-nginx"
  name      = "oauth2-proxy"

  values = [yamlencode({
    replicaCount = 2
    config = {
      existingSecret = "oauth2-proxy"
      configFile     = <<EOF
provider = "oidc"
redirect_url = "https://secure.${var.cluster_domain}/oauth2/callback"
oidc_issuer_url = "https://secure.${var.public_domain}"
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
      enabled = true
      serviceMonitor = {
        enabled = true
      }
    }

    sessionStorage = {
      type = "redis"

      redis = {
        existingSecret = "oauth2-proxy"
        passwordKey    = "redis-password"
        standalone = {
          connectionUrl = "rediss://${var.redis_host}:6379/5"
        }
      }
    }

    extraVolumes      = [var.ca_volume]
    extraVolumeMounts = [var.ca_volume_mount]
  })]
}


resource "kubectl_manifest" "oauth2_proxy_route" {
  depends_on = [helm_release.forgejo]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "oauth2-proxy"
      namespace = "sys-ingress-nginx"
      annotations = {
        "external-dns.alpha.kubernetes.io/target"             = var.loadbalancer_ip
        "external-dns.alpha.kubernetes.io/cloudflare-proxied" = "false"
      }
    }
    spec = {
      parentRefs = [
        {
          name        = "cilium"
          sectionName = "https"
          namespace   = "default"
        }
      ]
      hostnames = ["secure.${var.cluster_domain}"]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/oauth2"
              }
            }
          ]
          backendRefs = [
            {
              name = "oauth2-proxy"
              port = 80
            }
          ]
        }
      ]
    }
  })
}
