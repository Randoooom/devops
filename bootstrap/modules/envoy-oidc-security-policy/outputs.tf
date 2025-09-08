output "credentials" {
  sensitive = true
  value     = length(module.entra) == 1 ? module.entra[0].application_credentials : null
}

output "entra_issuer" {
  value = length(module.entra) == 1 ? module.entra[0].oidc_url : null
}

output "groups" {
  value = length(module.entra) == 1 ? module.entra[0].groups : null
}
