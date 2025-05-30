include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "oci" {
  path = find_in_parent_folders("oci.hcl")
}

dependency "network" {
  config_path = "${get_terragrunt_dir()}/../network"
}

inputs = {
  control_plane_security_group  = dependency.network.outputs.control_plane_security_group
  worker_security_group         = dependency.network.outputs.worker_security_group
  subnet                        = dependency.network.outputs.subnet
}
