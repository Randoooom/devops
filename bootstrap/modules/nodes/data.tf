data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.tenancy_ocid
}