output "oauth2_proxy_client_id" {
  sensitive = true
  value     = zitadel_application_oidc.oauth2_proxy.client_id
}

output "oauth2_proxy_client_secret" {
  sensitive = true
  value     = zitadel_application_oidc.oauth2_proxy.client_secret
}

output "argocd_client_id" {
  sensitive = true
  value     = zitadel_application_oidc.argocd.client_id
}

output "argocd_client_secret" {
  sensitive = true
  value     = zitadel_application_oidc.argocd.client_secret
}

output "zitadel_project" {
  value = zitadel_project.this.id
}

output "feedback_fusion_client_id" {
  sensitive = true
  value     = zitadel_application_oidc.feedback_fusion.client_id
}

output "feedback_fusion_client_secret" {
  sensitive = true
  value     = zitadel_application_oidc.feedback_fusion.client_secret
}

output "zitadel_feedback_fusion_id" {
  value = zitadel_application_oidc.feedback_fusion.id
}

output "forgejo_client_id" {
  value     = zitadel_application_oidc.forgejo.client_id
  sensitive = true
}

output "forgejo_client_secret" {
  value     = zitadel_application_oidc.forgejo.client_secret
  sensitive = true
}
