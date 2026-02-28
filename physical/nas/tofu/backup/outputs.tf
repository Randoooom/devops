output "backup_host_credentials" {
  sensitive = true

  value = {
    for host in var.backup_hosts : host => {
      user           = host
      access_key     = scaleway_iam_api_key.this[host].access_key
      secret_key     = scaleway_iam_api_key.this[host].secret_key
      application_id = scaleway_iam_application.this[host].id
    }
  }
}

output "backup_bucket" {
  sensitive = true
  value     = scaleway_object_bucket.this.name
}
