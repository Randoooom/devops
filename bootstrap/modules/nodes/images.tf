resource "oci_core_image" "talos_arm" {
  compartment_id = var.compartment_ocid

  display_name  = "Talos ${var.talos_version}"
  freeform_tags = var.labels
  launch_mode   = local.instance_mode

  image_source_details {
    source_type = "objectStorageUri"
    source_uri  = var.talos_image_oci_bucket_url

    operating_system         = "Talos"
    operating_system_version = var.talos_version
    source_image_type        = "QCOW2"
  }
}

resource "oci_core_shape_management" "talos_arm" {
  compartment_id = var.compartment_ocid
  image_id       = oci_core_image.talos_arm.id
  shape_name     = "VM.Standard.A1.Flex"
}
