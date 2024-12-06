resource "oci_identity_dynamic_group" "ccm" {
  name           = "${var.cluster_name}-oci-ccm"
  compartment_id = var.tenancy_ocid
  description    = "Instance access"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_ocid}'}"

  freeform_tags = var.labels
}

locals {
  ns_type_name   = strcontains(var.compartment_ocid, ".tenancy.") ? "tenancy" : "compartment"
  ns_select_name = strcontains(var.compartment_ocid, ".compartment.") ? data.oci_identity_compartment.this.name : ""
}


resource "oci_identity_policy" "ccm" {
  name           = "${var.cluster_name}-ccm"
  compartment_id = var.tenancy_ocid
  description    = "Instance access and OCI CSI driver permissions"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm.name} to read instance-family in ${local.ns_type_name} ${local.ns_select_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm.name} to use virtual-network-family in ${local.ns_type_name} ${local.ns_select_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm.name} to manage load-balancers in ${local.ns_type_name} ${local.ns_select_name}",
  ]

  freeform_tags = var.labels
}

