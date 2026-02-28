include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  defaults = include.root.locals.defaults
  userpass_file = "${get_terragrunt_dir()}/../../inventory/.output/openbao-userpass.sops.yaml" 
}

inputs = merge(local.defaults, fileexists(local.userpass_file) ? yamldecode(sops_decrypt_file(local.userpass_file)) : {})
