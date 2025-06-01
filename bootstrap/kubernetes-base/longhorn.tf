resource "kubernetes_namespace" "longhorn" {
  metadata {
    name = "sys-longhorn"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "longhorn" {
  depends_on = [kubernetes_namespace.longhorn]

  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = "1.9.0"

  namespace = "sys-longhorn"
  name      = "longhorn"

  values = [yamlencode({
    longhornUI = {
      replicas = 1
    }

    ingress = {
      enabled          = true
      ingressClassName = "internal"
      host             = "longhorn.internal.${var.cluster_domain}"
      annotations = {
        "nginx.ingress.kubernetes.io/auth-response-headers" = "Authorization"
        "nginx.ingress.kubernetes.io/auth-signin"           = "https://secure.${var.cluster_domain}/oauth2/start?rd=$scheme://$host$escaped_request_uri"
        "nginx.ingress.kubernetes.io/auth-url"              = "https://secure.${var.cluster_domain}/oauth2/auth"
        "nginx.ingress.kubernetes.io/configuration-snippet" = <<EOF
auth_request_set $name_upstream_1 $upstream_cookie_name_1;

access_by_lua_block {
  if ngx.var.name_upstream_1 ~= "" then
    ngx.header["Set-Cookie"] = "name_1=" .. ngx.var.name_upstream_1 .. ngx.var.auth_cookie:match("(; .*)")
  end
}
EOF
      }
    }
  })]
}
