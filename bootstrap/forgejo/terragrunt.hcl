include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "forgejo" {
  path = find_in_parent_folders("forgejo.hcl")
}

dependency "kubernetes_full" {
  config_path = "${get_terragrunt_dir()}/../kubernetes-full"  
}

inputs = {
  forgejo_host       = dependency.kubernetes_full.outputs.forgejo_host
  forgejo_username   = dependency.kubernetes_full.outputs.forgejo_username
  forgejo_password   = dependency.kubernetes_full.outputs.forgejo_password
}
