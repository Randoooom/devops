include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "kubernetes" {
  path = find_in_parent_folders("kubernetes.hcl")
}

dependency "talos" {
  config_path = "${get_terragrunt_dir()}/../talos"
}

dependency "zitadel" {
  config_path = "${get_terragrunt_dir()}/../zitadel"
}

inputs = {
  kubeconfig                  = dependency.talos.outputs.kubeconfig
  argocd_client_id            = dependency.zitadel.outputs.argocd_client_id
  argocd_client_secret        = dependency.zitadel.outputs.argocd_client_secret
  oauth2_proxy_client_id      = dependency.zitadel.outputs.oauth2_proxy_client_id
  oauth2_proxy_client_secret  = dependency.zitadel.outputs.oauth2_proxy_client_secret
  zitadel_project             = dependency.zitadel.outputs.zitadel_project
}
