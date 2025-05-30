output "bastion_sessions" {
  value     = jsonencode(concat([oci_bastion_session.kubernetes_controlplane], values(oci_bastion_session.controlplane), values(oci_bastion_session.worker)))
  sensitive = true
}

output "region" {
  value = var.region
}
