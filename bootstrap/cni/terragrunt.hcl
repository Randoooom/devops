include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "kubernetes" {
  path = find_in_parent_folders("kubernetes.hcl")
}

dependency "talos" {
  config_path = "${get_terragrunt_dir()}/../talos"
}

dependency "network" {
  config_path = "${get_terragrunt_dir()}/../network"
}

inputs = {
  kubeconfig    = dependency.talos.outputs.kubeconfig
  public_subnet = dependency.network.outputs.public_subnet
}
