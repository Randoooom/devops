output "kubeconfig" {
  value     = module.talos.kubeconfig
  sensitive = true
}

output "talos_client_configuration" {
  value     = module.talos.talos_client_configuration
  sensitive = true
}
