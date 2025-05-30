resource "oci_core_nat_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id

  freeform_tags = var.labels
  display_name  = "${var.cluster_name}-nat-gateway"
}

resource "oci_core_service_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  services {
    service_id = data.oci_core_services.this.services.0.id
  }

  display_name  = "${var.cluster_name}-service-gateway"
  freeform_tags = var.labels
}

resource "oci_core_route_table" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id

  display_name  = var.cluster_name
  freeform_tags = var.labels

  route_rules {
    network_entity_id = oci_core_nat_gateway.this.id

    destination_type = "CIDR_BLOCK"
    destination      = "0.0.0.0/0"
  }

  route_rules {
    network_entity_id = oci_core_service_gateway.this.id

    destination_type = "SERVICE_CIDR_BLOCK"
    destination      = data.oci_core_services.this.services.0.cidr_block
  }
}

resource "oci_core_network_security_group" "nodes" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id

  display_name  = var.cluster_name
  freeform_tags = var.labels
}

resource "oci_core_network_security_group_security_rule" "allow_egress" {
  network_security_group_id = oci_core_network_security_group.nodes.id
  destination_type          = "CIDR_BLOCK"
  destination               = "0.0.0.0/0"
  protocol                  = "all"
  direction                 = "EGRESS"
  stateless                 = false
}

resource "oci_core_network_security_group_security_rule" "allow_kubernetes_ingress" {
  network_security_group_id = oci_core_network_security_group.nodes.id
  source_type               = "CIDR_BLOCK"
  source                    = "0.0.0.0/0"
  protocol                  = "6"
  direction                 = "INGRESS"
  stateless                 = false

  tcp_options {
    destination_port_range {
      max = 6443
      min = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "allow_talos_ingress" {
  network_security_group_id = oci_core_network_security_group.nodes.id
  source_type               = "CIDR_BLOCK"
  source                    = "0.0.0.0/0"
  protocol                  = "6"
  direction                 = "INGRESS"
  stateless                 = false

  tcp_options {
    destination_port_range {
      max = 50000
      min = 50000
    }
  }
}

resource "oci_core_security_list" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id

  display_name  = var.cluster_name
  freeform_tags = var.labels

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"

    stateless = false
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "all"

    stateless = false
  }
}

resource "oci_core_subnet" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id

  cidr_block                 = var.subnet_cidr
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
  display_name               = var.cluster_name
  freeform_tags              = var.labels
  security_list_ids          = [oci_core_security_list.this.id]
  route_table_id             = oci_core_route_table.this.id
}

resource "oci_core_internet_gateway" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.cluster_name}-public-igw"
  freeform_tags  = var.labels
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id

  display_name  = "${var.cluster_name}-public"
  freeform_tags = var.labels

  route_rules {
    network_entity_id = oci_core_internet_gateway.public.id

    destination_type = "CIDR_BLOCK"
    destination      = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id

  cidr_block                 = var.public_cidr
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  display_name               = "${var.cluster_name}-public"
  freeform_tags              = var.labels
  security_list_ids          = [oci_core_security_list.this.id]
  route_table_id             = oci_core_route_table.public.id
}
