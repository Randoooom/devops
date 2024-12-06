resource "oci_core_instance" "controlplane" {
  count = var.control_plane_count

  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[count.index % length(data.oci_identity_availability_domains.availability_domains.availability_domains)].name
  shape               = "VM.Standard.A1.Flex"
  display_name        = "${var.cluster_name}-controlplane-${count.index}"
  freeform_tags       = var.labels

  shape_config {
    ocpus         = var.control_plane_ocpu
    memory_in_gbs = var.control_plane_ram
  }

  create_vnic_details {
    assign_public_ip = false
    subnet_id        = var.subnet
    nsg_ids          = [var.control_plane_security_group]
  }

  agent_config {
    are_all_plugins_disabled = true
    is_management_disabled   = true
    is_monitoring_disabled   = true
  }

  availability_config {
    is_live_migration_preferred = true
    recovery_action             = "RESTORE_INSTANCE"
  }

  launch_options {
    network_type            = local.instance_mode
    remote_data_volume_type = local.instance_mode
    boot_volume_type        = local.instance_mode
    firmware                = "UEFI_64"
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  source_details {
    source_type             = "image"
    source_id               = oci_core_image.talos_arm.id
    boot_volume_size_in_gbs = "50"
  }
  preserve_boot_volume = false

  lifecycle {
    create_before_destroy = "true"
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_instance" "worker" {
  count      = var.worker_count
  depends_on = [oci_core_instance.controlplane]

  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[count.index % length(data.oci_identity_availability_domains.availability_domains.availability_domains)].name
  shape               = "VM.Standard.A1.Flex"
  display_name        = "${var.cluster_name}-worker-${count.index}"
  freeform_tags       = var.labels

  shape_config {
    ocpus         = var.worker_ocpu
    memory_in_gbs = var.worker_ram
  }

  create_vnic_details {
    assign_public_ip = false
    subnet_id        = var.subnet
    nsg_ids          = [var.worker_security_group]
  }

  agent_config {
    are_all_plugins_disabled = true
    is_management_disabled   = true
    is_monitoring_disabled   = true
  }

  availability_config {
    is_live_migration_preferred = true
    recovery_action             = "RESTORE_INSTANCE"
  }

  launch_options {
    network_type            = local.instance_mode
    remote_data_volume_type = local.instance_mode
    boot_volume_type        = local.instance_mode
    firmware                = "UEFI_64"
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  source_details {
    source_type             = "image"
    source_id               = oci_core_image.talos_arm.id
    boot_volume_size_in_gbs = "50"
  }
  preserve_boot_volume = false

  lifecycle {
    create_before_destroy = "true"
    ignore_changes = [
      defined_tags
    ]
  }
}
