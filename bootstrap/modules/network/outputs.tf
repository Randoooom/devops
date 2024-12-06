output "subnet" {
  value = oci_core_subnet.this.id
}

output "worker_security_group" {
  value = oci_core_network_security_group.nodes.id
}

output "control_plane_security_group" {
  value = oci_core_network_security_group.nodes.id
}

output "vcn_id" {
  value = oci_core_vcn.this.id
}

output "security_list_id" {
  value = oci_core_security_list.this.id
}

output "public_subnet" {
  value = oci_core_subnet.public.id
}

output "public_subnet_cidr" {
  value = oci_core_subnet.public.cidr_block
}
