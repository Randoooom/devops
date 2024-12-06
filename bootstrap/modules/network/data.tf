data "oci_identity_compartment" "this" {
  id = var.compartment_ocid
}

data "oci_core_services" "this" {}
