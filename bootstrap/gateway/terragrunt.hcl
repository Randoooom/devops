include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "kubernetes" {
  path = find_in_parent_folders("kubernetes.hcl")
}

dependency "cni" {
  config_path = "${get_terragrunt_dir()}/../cni"
}

dependency "talos" {
  config_path = "${get_terragrunt_dir()}/../talos"
}

dependency "nodes" {
  config_path = "${get_terragrunt_dir()}/../nodes"
}

inputs = {
  kubeconfig           = dependency.talos.outputs.kubeconfig
  public_loadbalancer_ip = dependency.cni.outputs.public_loadbalancer_ip
  controlplane         = dependency.nodes.outputs.controlplane
}
