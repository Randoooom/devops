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
  version    = "7.12.18"

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
    ingress = {
      enabled   = true
      hosts     = ["secure.${var.cluster_domain}"]
      className = "cilium"
      path      = "/oauth2"
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
  })]
}
