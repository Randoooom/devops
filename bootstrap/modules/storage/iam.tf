resource "oci_identity_user" "nextcloud" {
  compartment_id = var.tenancy_ocid
  description    = "NextCloud user"
  name           = "nextcloud"
  email          = "nextcloud@${var.domain}"
}

resource "oci_identity_customer_secret_key" "nextcloud" {
  display_name = "nextcloud"
  user_id      = oci_identity_user.nextcloud.id
}

resource "oci_identity_group" "nextcloud" {
  compartment_id = var.tenancy_ocid
  description    = "NextCloud"
  name           = "nextcloud"
}

resource "oci_identity_policy" "nextcloud" {
  compartment_id = var.tenancy_ocid
  description    = "NextCloud Bucket access"
  name           = "nextcloud"
  statements     = ["ALLOW group ${oci_identity_group.nextcloud.name} TO manage buckets IN TENANCY where all {target.bucket.name = '${var.cluster_name}-nextcloud'}", "ALLOW group ${oci_identity_group.nextcloud.name} TO manage objects IN TENANCY where all {target.bucket.name = '${var.cluster_name}-nextcloud'}"]
}

resource "oci_identity_user_group_membership" "nextcloud" {
  group_id = oci_identity_group.nextcloud.id
  user_id  = oci_identity_user.nextcloud.id
}
