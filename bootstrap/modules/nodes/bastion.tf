resource "oci_bastion_bastion" "this" {
  compartment_id               = var.compartment_ocid
  target_subnet_id             = var.subnet
  bastion_type                 = "STANDARD"
  client_cidr_block_allow_list = ["0.0.0.0/0"]
}


resource "null_resource" "always_run" {
  triggers = {
    timestamp = "${timestamp()}"
  }
}

resource "oci_bastion_session" "controlplane" {
  for_each = local.controlplane

  bastion_id   = oci_bastion_bastion.this.id
  display_name = "${var.cluster_name}-${each.value.display_name}"

  key_details {
    public_key_content = var.ssh_public_key
  }

  target_resource_details {
    session_type                       = "PORT_FORWARDING"
    target_resource_id                 = each.value.id
    target_resource_private_ip_address = each.value.private_ip
    target_resource_port               = 50000
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.always_run
    ]
  }
}

resource "oci_bastion_session" "worker" {
  for_each = local.workers

  bastion_id   = oci_bastion_bastion.this.id
  display_name = "${var.cluster_name}-${each.value.display_name}"

  key_details {
    public_key_content = var.ssh_public_key
  }

  target_resource_details {
    session_type                       = "PORT_FORWARDING"
    target_resource_id                 = each.value.id
    target_resource_private_ip_address = each.value.private_ip
    target_resource_port               = 50000
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.always_run
    ]
  }
}

resource "oci_bastion_session" "kubernetes_controlplane" {
  bastion_id   = oci_bastion_bastion.this.id
  display_name = "${var.cluster_name}-kubernetes-controlplane"

  key_details {
    public_key_content = var.ssh_public_key
  }

  target_resource_details {
    session_type                       = "PORT_FORWARDING"
    target_resource_id                 = oci_core_instance.controlplane[0].id
    target_resource_private_ip_address = oci_core_instance.controlplane[0].private_ip
    target_resource_port               = 6443
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.always_run
    ]
  }
}
