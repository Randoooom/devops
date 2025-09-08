include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "oci" {
  path = find_in_parent_folders("oci.hcl")
}

include "kubernetes" {
  path = find_in_parent_folders("kubernetes.hcl")
}

include "entra" {
  path = find_in_parent_folders("entra.hcl")
}

dependency "talos" {
  config_path = "${get_terragrunt_dir()}/../talos"
}

dependency "network" {
  config_path = "${get_terragrunt_dir()}/../network"
}

dependency "nodes" {
  config_path = "${get_terragrunt_dir()}/../nodes"
}

inputs = {
  kubeconfig    = dependency.talos.outputs.kubeconfig

  public_subnet = dependency.network.outputs.public_subnet
  private_subnet = dependency.network.outputs.subnet
  vcn_id        = dependency.network.outputs.vcn_id

  worker       = dependency.nodes.outputs.worker
  controlplane = dependency.nodes.outputs.controlplane
}
