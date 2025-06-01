output "groups" {
  value = {
    for group_name, group in var.groups : group_name => {
      group_identity = oci_identity_group.this[group_name].id
      users = {
        for user in group.users : user.name => {
          user_identity       = oci_identity_user.this["${group_name}-${user.name}"]
          customer_secret_key = try(oci_identity_customer_secret_key.this["${group_name}-${user.name}"], null)
          smtp_credentials    = try(oci_identity_smtp_credential.this["${group_name}-${user.name}"], null)
        }
      }
    }
  }
  sensitive = true
}
