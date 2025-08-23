output "application_credentials" {
  value = {
    for app_name in keys(azuread_application.additional) :
    app_name => {
      client_id     = azuread_application.additional[app_name].client_id
      client_secret = azuread_application_password.additional[app_name].value
    }
  }
  sensitive = true
}

output "oidc_url" {
  value     = "https://login.microsoftonline.com/${var.azure_tenant_id}/v2.0"
  sensitive = true
}

output "groups" {
  value = { for group in azuread_group.this: group.display_name => group.object_id }
}
