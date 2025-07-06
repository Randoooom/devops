locals {
  loadbalancer_ip = [for ip in oci_network_load_balancer_network_load_balancer.this.ip_addresses : ip.ip_address if ip.is_public][0]
}

resource "oci_network_load_balancer_network_load_balancer" "this" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-shared"
  subnet_id      = var.public_subnet

  is_private                 = false
  network_security_group_ids = [oci_core_network_security_group.nlb.id]
}


resource "oci_network_load_balancer_backend_set" "services" {
  for_each = var.services

  name                     = "${replace(each.key, "_", "-")}-bs" # Eindeutiger Name pro Service, z.B. "http-bs"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.this.id
  policy                   = "FIVE_TUPLE"

  health_checker {
    protocol           = "TCP"
    port               = 10256
    interval_in_millis = 10000
    timeout_in_millis  = 3000
    retries            = 3
  }
}

# Erstellt für jeden Service einen eigenen Listener
resource "oci_network_load_balancer_listener" "services" {
  for_each = var.services

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.this.id
  name                     = replace(each.key, "_", "-")
  port                     = each.value.port
  protocol                 = each.value.protocol

  default_backend_set_name = oci_network_load_balancer_backend_set.services[each.key].name
}


resource "oci_network_load_balancer_backend" "nodes" {
  for_each = {
    for pair in setproduct(keys(var.services), var.worker) : "${pair[0]}-${pair[1].id}" => {
      service     = var.services[pair[0]]
      service_key = pair[0]
      worker      = pair[1]
    }
  }

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.this.id
  backend_set_name         = oci_network_load_balancer_backend_set.services[each.value.service_key].name

  target_id = each.value.worker.id
  port      = each.value.service.node_port
  weight    = 1
}

