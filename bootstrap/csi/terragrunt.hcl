include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "kubernetes" {
  path = find_in_parent_folders("kubernetes.hcl")
}

include "entra" {
  path = find_in_parent_folders("entra.hcl")
}

dependencies {
  paths = ["${get_terragrunt_dir()}/../cni"]
}

dependency "nodes" {
  config_path = "${get_terragrunt_dir()}/../nodes"
}

dependency "talos" {
  config_path = "${get_terragrunt_dir()}/../talos"
}

inputs = {
  kubeconfig           = dependency.talos.outputs.kubeconfig
  controlplane         = dependency.nodes.outputs.controlplane
}
