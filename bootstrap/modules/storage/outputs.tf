output "bucket_namespace" {
  sensitive = true
  value     = data.oci_objectstorage_namespace.this.namespace
}

output "nextcloud_access_key_id" {
  sensitive = true
  value     = oci_identity_customer_secret_key.nextcloud.id
}


output "nextcloud_secret_access_key" {
  sensitive = true
  value     = oci_identity_customer_secret_key.nextcloud.key
}
