resource "oci_core_volume" "worker" {
  for_each = { for idx, value in oci_core_instance.worker : idx => value }

  compartment_id = var.compartment_ocid

  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[each.key % length(data.oci_identity_availability_domains.availability_domains.availability_domains)].name
  display_name        = each.value.display_name
  freeform_tags       = var.labels
  size_in_gbs         = 50

  lifecycle {
    create_before_destroy = "true"
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_volume_attachment" "worker_volume_attachment" {
  for_each = { for idx, value in oci_core_volume.worker : idx => value }

  attachment_type = local.instance_mode
  instance_id     = [for value in oci_core_instance.worker : value if value.display_name == each.value.display_name][0].id
  volume_id       = each.value.id
}
