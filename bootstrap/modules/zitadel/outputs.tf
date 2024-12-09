output "oauth2_proxy_client_id" {
  sensitive = true
  value     = zitadel_application_oidc.oauth2_proxy.client_id
}

output "oauth2_proxy_client_secret" {
  sensitive = true
  value     = zitadel_application_oidc.oauth2_proxy.client_secret
}

output "grafana_client_id" {
  sensitive = true
  value     = zitadel_application_oidc.grafana.client_id
}

output "grafana_client_secret" {
  sensitive = true
  value     = zitadel_application_oidc.grafana.client_secret
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
