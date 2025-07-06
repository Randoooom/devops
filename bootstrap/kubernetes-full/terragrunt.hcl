include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "kubernetes" {
  path = find_in_parent_folders("kubernetes.hcl")
}

include "oci" {
  path = find_in_parent_folders("oci.hcl")
}

dependency "storage" {
  config_path = "${get_terragrunt_dir()}/../storage"
}

dependency "talos" {
  config_path = "${get_terragrunt_dir()}/../talos"
}

dependency "zitadel" {
  config_path = "${get_terragrunt_dir()}/../zitadel"
}

dependency "mail" {
  config_path = "${get_terragrunt_dir()}/../mail"
}

dependency "databases" {
  config_path = "${get_terragrunt_dir()}/../databases"
}

dependency "cni" {
  config_path = "${get_terragrunt_dir()}/../cni"
}

dependency "nodes" {
  config_path = "${get_terragrunt_dir()}/../nodes"
}

inputs = {
  kubeconfig                  = dependency.talos.outputs.kubeconfig
  argocd_client_id            = dependency.zitadel.outputs.argocd_client_id
  argocd_client_secret        = dependency.zitadel.outputs.argocd_client_secret
  oauth2_proxy_client_id      = dependency.zitadel.outputs.oauth2_proxy_client_id
  oauth2_proxy_client_secret  = dependency.zitadel.outputs.oauth2_proxy_client_secret
  forgejo_client_id           = dependency.zitadel.outputs.forgejo_client_id
  forgejo_client_secret       = dependency.zitadel.outputs.forgejo_client_secret
  zitadel_project             = dependency.zitadel.outputs.zitadel_project
  forgejo_bucket              = dependency.storage.outputs.buckets["forgejo"]
  bucket_endpoint             = dependency.storage.outputs.bucket_endpoint

  smtp_host   = dependency.mail.outputs.smtp_host
  smtp_sender = dependency.mail.outputs.senders

  redis_host     = dependency.databases.outputs.redis_host
  redis_password = dependency.databases.outputs.redis_password

  loadbalancer_ip = dependency.cni.outputs.loadbalancer_ip
  ca_volume       = dependency.cni.outputs.ca_volume
  ca_volume_mount = dependency.cni.outputs.ca_volume_mount

  postgres_host            = dependency.databases.outputs.postgres_host
  postgres_databases       = dependency.databases.outputs.postgres_databases

  controlplane         = dependency.nodes.outputs.controlplane
}
