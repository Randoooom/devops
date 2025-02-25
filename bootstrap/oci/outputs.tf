output "worker" {
  value = module.nodes.worker
}

output "controlplane" {
  value = module.nodes.controlplane
}

output "region" {
  value = var.region
}

output "vcn_id" {
  value = module.network.vcn_id
}

output "subnet_id" {
  value = module.network.subnet
}

output "security_list_id" {
  value = module.network.security_list_id
}

output "public_subnet" {
  value = module.network.public_subnet
}

output "vault" {
  sensitive = true
  value     = module.vault.vault
}

output "public_subnet_cidr" {
  value = module.network.public_subnet_cidr
}

output "zitadel_project" {
  value = module.zitadel.zitadel_project
}

output "feedback_fusion_client_id" {
  sensitive = true
  value     = module.zitadel.feedback_fusion_client_id
}

output "feedback_fusion_client_secret" {
  sensitive = true
  value     = module.zitadel.feedback_fusion_client_secret
}

output "zitadel_feedback_fusion_id" {
  value = module.zitadel.zitadel_feedback_fusion_id
}

output "grafana_client_id" {
  sensitive = true
  value     = module.zitadel.grafana_client_id
}

output "grafana_client_secret" {
  sensitive = true
  value     = module.zitadel.grafana_client_secret
}
