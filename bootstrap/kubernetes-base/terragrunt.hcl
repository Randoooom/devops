include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "kubernetes" {
  path = find_in_parent_folders("kubernetes.hcl")
}

dependency "network" {
  config_path = "${get_terragrunt_dir()}/../network"
}

dependency "talos" {
  config_path = "${get_terragrunt_dir()}/../talos"
}

dependency "storage" {
  config_path = "${get_terragrunt_dir()}/../storage"
}

inputs = {
  public_subnet        = dependency.network.outputs.public_subnet
  public_subnet_cidr   = dependency.network.outputs.public_subnet_cidr
  private_subnet       = dependency.network.outputs.subnet
  kubeconfig           = dependency.talos.outputs.kubeconfig
  bucket_endpoint      = dependency.storage.outputs.bucket_endpoint
  buckets              = dependency.storage.outputs.buckets
}
