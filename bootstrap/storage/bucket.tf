resource "oci_identity_user" "bucket" {
  for_each = toset(var.buckets)

  compartment_id = var.tenancy_ocid
  description    = each.key
  name           = each.key
}

resource "oci_identity_customer_secret_key" "bucket" {
  for_each = toset(var.buckets)

  display_name = each.key
  user_id      = oci_identity_user.bucket[each.key].id
}

resource "oci_identity_group" "bucket" {
  for_each = toset(var.buckets)

  compartment_id = var.tenancy_ocid
  description    = each.key
  name           = each.key
}

resource "oci_identity_policy" "bucket" {
  for_each = toset(var.buckets)

  compartment_id = var.tenancy_ocid
  description    = "${each.key} Bucket access"
  name           = each.key
  statements     = ["ALLOW group ${oci_identity_group.bucket[each.key].name} TO manage buckets IN TENANCY where all {target.bucket.name = '${oci_objectstorage_bucket.bucket[each.key].name}'}", "ALLOW group ${oci_identity_group.bucket[each.key].name} TO manage objects IN TENANCY where all {target.bucket.name = '${oci_objectstorage_bucket.bucket[each.key].name}'}"]
}

resource "oci_identity_user_group_membership" "bucket" {
  for_each = toset(var.buckets)

  group_id = oci_identity_group.bucket[each.key].id
  user_id  = oci_identity_user.bucket[each.key].id
}

resource "oci_objectstorage_bucket" "bucket" {
  for_each = toset(var.buckets)

  compartment_id = var.compartment_ocid
  name           = "${var.cluster_name}-${each.key}"
  namespace      = data.oci_objectstorage_namespace.this.namespace
}

locals {
  buckets = { for bucket in toset(var.buckets) : bucket => tomap({
    id   = oci_identity_customer_secret_key.bucket[bucket].id
    key  = oci_identity_customer_secret_key.bucket[bucket].key
    name = "${var.cluster_name}-${bucket}"
  }) }
}
