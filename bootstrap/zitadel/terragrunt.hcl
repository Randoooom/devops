include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "kubernetes" {
  path = find_in_parent_folders("kubernetes.hcl")
}

dependency "talos" {
  config_path = "${get_terragrunt_dir()}/../talos"
}

dependencies {
  paths = ["${get_terragrunt_dir()}/../kubernetes-base"]
}

inputs = {
  kubeconfig           = dependency.talos.outputs.kubeconfig
}
