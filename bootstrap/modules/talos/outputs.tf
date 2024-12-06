output "kubeconfig" {
  value     = talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}

output "talos_client_configuration" {
  value     = data.talos_client_configuration.this
  sensitive = true
}
