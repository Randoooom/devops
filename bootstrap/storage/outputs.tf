output "buckets" {
  sensitive = true
  value     = local.buckets
}

output "bucket_endpoint" {
  sensitive = true
  value     = "${data.oci_objectstorage_namespace.this.namespace}.compat.objectstorage.${var.region}.oraclecloud.com:443"
}
