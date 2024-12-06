output "worker_ips" {
  value = module.nodes.worker_ips
}

output "controlplane_ips" {
  value = module.nodes.controlplane_ips
}

output "bastion_sessions" {
  value     = module.nodes.bastion_sessions
  sensitive = true
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
