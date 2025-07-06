include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "kubernetes" {
  path = find_in_parent_folders("kubernetes.hcl")
}

dependency "storage" {
  config_path = "${get_terragrunt_dir()}/../storage"
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
  bucket_endpoint      = dependency.storage.outputs.bucket_endpoint
  buckets              = dependency.storage.outputs.buckets

  loadbalancer_ip = dependency.cni.outputs.loadbalancer_ip

  controlplane         = dependency.nodes.outputs.controlplane
}
