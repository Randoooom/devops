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
  subnet_id      = dependency.network.outputs.subnet
  worker         = dependency.nodes.outputs.worker
  controlplane   = dependency.nodes.outputs.controlplane
}
