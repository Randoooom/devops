resource "grafana_sso_settings" "zitadel" {
  provider = grafana.stack

  provider_name = "generic_oauth"

  oauth2_settings {
    name              = "Zitadel"
    client_id         = var.zitadel_grafana_client_id
    client_secret     = var.zitadel_grafana_client_secret
    allow_sign_up     = true
    auto_login        = false
    scopes            = "openid profile email offline_access"
    use_pkce          = false
    use_refresh_token = true

    auth_url  = "https://${var.zitadel_host}/oauth/v2/authorize"
    token_url = "https://${var.zitadel_host}/oauth/v2/token"
    api_url   = "https://${var.zitadel_host}/oidc/v1/userinfo"

    allowed_groups        = "${var.zitadel_project}:grafana-editor ${var.zitadel_project}:grafana-viewer"
    groups_attribute_path = "groups"
  }
}
