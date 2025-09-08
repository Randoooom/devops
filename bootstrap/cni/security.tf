resource "oci_core_network_security_group" "nlb" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_id
  display_name   = "${var.cluster_name}-nlb-nsg"
}

resource "oci_core_network_security_group_security_rule" "service_ingress" {
  for_each = var.public_services

  network_security_group_id = oci_core_network_security_group.nlb.id
  direction                 = "INGRESS"
  protocol                  = each.value.protocol == "TCP" ? "6" : "17"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  dynamic "tcp_options" {
    for_each = each.value.protocol == "TCP" ? [1] : []
    content {
      destination_port_range {
        min = each.value.port
        max = each.value.port
      }
    }
  }

  dynamic "udp_options" {
    for_each = each.value.protocol == "UDP" ? [1] : []
    content {
      destination_port_range {
        min = each.value.port
        max = each.value.port
      }
    }
  }
}

resource "oci_core_network_security_group_security_rule" "udp" {
  network_security_group_id = oci_core_network_security_group.nlb.id
  direction                 = "INGRESS"
  protocol                  = "17"
  source                    = "10.0.1.0/24"
  source_type               = "CIDR_BLOCK"

  udp_options {
    destination_port_range {
      min = 30000
      max = 32767
    }
  }
}

resource "oci_core_network_security_group_security_rule" "tcp" {
  network_security_group_id = oci_core_network_security_group.nlb.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "10.0.1.0/24"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 30000
      max = 32767
    }
  }
}
