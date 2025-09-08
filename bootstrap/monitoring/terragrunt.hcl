include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "kubernetes" {
  path = find_in_parent_folders("kubernetes.hcl")
}

dependency "talos" {
  config_path = "${get_terragrunt_dir()}/../talos"
}

dependency "gateway" {
  config_path = "${get_terragrunt_dir()}/../gateway"
}

dependency "nodes" {
  config_path = "${get_terragrunt_dir()}/../nodes"
}

inputs = {
  kubeconfig           = dependency.talos.outputs.kubeconfig

  ca_volume       = dependency.gateway.outputs.ca_volume
  ca_volume_mount = dependency.gateway.outputs.ca_volume_mount

  controlplane         = dependency.nodes.outputs.controlplane
}
