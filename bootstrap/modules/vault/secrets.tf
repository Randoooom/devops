locals {
  secrets = [
    {
      name = "oauth2-proxy-cookie-secret"
      generate = {
        length = 32
      }
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
    },

    {
      name = "feedback-fusion-postgres-admin-password"
      generate = {
        length = 60
      }
    },
    {
      name = "feedback-fusion-postgres-replication-password"
      generate = {
        length = 60
      }
    },
    {
      name = "feedback-fusion-postgres-password"
      generate = {
        length = 60
      }
    },

    {
      name = "surrealdb-username"
      generate = {
        length = 10
      }
    },
    {
      name = "surrealdb-password"
      generate = {
        length = 60
      }
    }
  ]
}

resource "random_password" "this" {
  for_each = { for secret in local.secrets : secret.name => secret.generate if contains(keys(secret), "generate") }

  length  = each.value.length
  special = false
}

resource "oci_vault_secret" "this" {
  for_each = { for secret in local.secrets : secret.name => secret }

  compartment_id = var.compartment_id
  vault_id       = oci_kms_vault.this.id
  key_id         = oci_kms_key.this.id

  secret_name = each.value.name

  secret_content {
    content_type = "BASE64"
    content      = base64encode(contains(keys(each.value), "generate") ? random_password.this[each.key].result : each.value.value)
  }
}
