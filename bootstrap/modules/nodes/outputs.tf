output "worker_ips" {
  value = [for instance in oci_core_instance.worker : instance.private_ip]
}

output "controlplane_ips" {
  value = [for instance in oci_core_instance.controlplane : instance.private_ip]
}

output "bastion_sessions" {
  value     = jsonencode(concat([oci_bastion_session.kubernetes_controlplane], values(oci_bastion_session.controlplane), values(oci_bastion_session.worker)))
  sensitive = true
}
