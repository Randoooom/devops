resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_ocid

  display_name  = "${var.cluster_name}-vcn"
  cidr_blocks   = var.vcn_cidrs
  freeform_tags = var.labels
}
