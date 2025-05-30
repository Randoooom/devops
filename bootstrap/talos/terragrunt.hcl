include {
  path = find_in_parent_folders("root.hcl")
}

dependency "network" {
  config_path = "${get_terragrunt_dir()}/../network"
}

dependency "nodes" {
  config_path = "${get_terragrunt_dir()}/../nodes"
}

inputs = {
  vcn_id               = dependency.network.outputs.vcn_id
  worker               = dependency.nodes.outputs.worker
  controlplane         = dependency.nodes.outputs.controlplane
  security_list_id     = dependency.network.outputs.security_list_id
  subnet_id            = dependency.network.outputs.subnet
  public_subnet        = dependency.network.outputs.public_subnet
}
