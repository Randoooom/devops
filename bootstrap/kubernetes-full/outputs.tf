output "forgejo_host" {
  sensitive = true
  value     = "https://git.${var.public_domain}"
}

output "forgejo_username" {
  value = "forgejo-admin"
}

output "forgejo_password" {
  sensitive = true
  value     = random_password.forgejo_admin.result
}
