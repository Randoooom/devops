resource "zitadel_application_oidc" "oauth2_proxy" {
  org_id     = local.zitadel_org
  project_id = zitadel_project.this.id

  name                        = "OAuth2Proxy"
  redirect_uris               = ["https://secure.${var.cluster_domain}/oauth2/callback"]
  response_types              = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  post_logout_redirect_uris   = []
  app_type                    = "OIDC_APP_TYPE_WEB"
  auth_method_type            = "OIDC_AUTH_METHOD_TYPE_BASIC"
  version                     = "OIDC_VERSION_1_0"
  clock_skew                  = "0s"
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
  access_token_role_assertion = true
  id_token_role_assertion     = true
  id_token_userinfo_assertion = false
}

resource "zitadel_application_oidc" "argocd" {
  org_id     = local.zitadel_org
  project_id = zitadel_project.this.id

  name                        = "ArgoCD"
  redirect_uris               = ["https://argocd.internal.${var.cluster_domain}/auth/callback"]
  response_types              = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  post_logout_redirect_uris   = []
  app_type                    = "OIDC_APP_TYPE_WEB"
  auth_method_type            = "OIDC_AUTH_METHOD_TYPE_BASIC"
  version                     = "OIDC_VERSION_1_0"
  clock_skew                  = "0s"
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
  access_token_role_assertion = true
  id_token_role_assertion     = true
  id_token_userinfo_assertion = false
}

resource "zitadel_application_oidc" "feedback_fusion" {
  org_id     = local.zitadel_org
  project_id = zitadel_project.this.id

  name                        = "feedback-fusion"
  redirect_uris               = ["https://feedback-fusion.${var.public_domain}/auth/oidc/callback"]
  response_types              = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  post_logout_redirect_uris   = []
  app_type                    = "OIDC_APP_TYPE_WEB"
  auth_method_type            = "OIDC_AUTH_METHOD_TYPE_BASIC"
  version                     = "OIDC_VERSION_1_0"
  clock_skew                  = "0s"
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
  access_token_role_assertion = true
  id_token_role_assertion     = true
  id_token_userinfo_assertion = false
}

resource "zitadel_application_oidc" "forgejo" {
  org_id     = local.zitadel_org
  project_id = zitadel_project.this.id

  name                        = "forgejo"
  redirect_uris               = ["https://git.${var.public_domain}/user/oauth2/Zitadel/callback"]
  response_types              = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  post_logout_redirect_uris   = []
  app_type                    = "OIDC_APP_TYPE_WEB"
  auth_method_type            = "OIDC_AUTH_METHOD_TYPE_BASIC"
  version                     = "OIDC_VERSION_1_0"
  clock_skew                  = "0s"
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
  access_token_role_assertion = true
  id_token_role_assertion     = true
  id_token_userinfo_assertion = false
}

resource "zitadel_application_oidc" "additional_application" {
  for_each = var.additional_applications

  org_id     = local.zitadel_org
  project_id = zitadel_project.this.id

  name                        = each.key
  redirect_uris               = each.value.redirect_uris
  response_types              = each.value.response_types
  grant_types                 = each.value.grant_types
  post_logout_redirect_uris   = each.value.post_logout_redirect_uris
  app_type                    = each.value.app_type
  auth_method_type            = "OIDC_AUTH_METHOD_TYPE_BASIC"
  version                     = "OIDC_VERSION_1_0"
  clock_skew                  = "0s"
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
  access_token_role_assertion = true
  id_token_role_assertion     = true
  id_token_userinfo_assertion = false
}
