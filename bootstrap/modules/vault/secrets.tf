locals {
  secrets = [
    {
      name  = "oauth2-proxy-cookie-secret"
      value = random_password.oauth2_proxy_cookie_secret.result
    },
    {
      name  = "oauth2-proxy-client-id"
      value = var.oauth2_proxy_client_id
    },
    {
      name  = "oauth2-proxy-client-secret"
      value = var.oauth2_proxy_client_secret
    },

    {
      name  = "grafana-client-id"
      value = var.grafana_client_id
    },
    {
      name  = "grafana-client-secret"
      value = var.grafana_client_secret
    },

    {
      name  = "argocd-client-id"
      value = var.argocd_client_id
    },
    {
      name  = "argocd-client-secret"
      value = var.argocd_client_secret
    }
  ]
}

resource "random_password" "oauth2_proxy_cookie_secret" {
  length  = 32
  special = false
}

resource "oci_vault_secret" "this" {
  for_each = { for id, value in local.secrets : id => value }

  compartment_id = var.compartment_id
  vault_id       = oci_kms_vault.this.id
  key_id         = oci_kms_key.this.id

  secret_name = each.value.name

  secret_content {
    content_type = "BASE64"
    content      = base64encode(each.value.value)
  }
}
