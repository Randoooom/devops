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

dependency "entra" {
  config_path = "${get_terragrunt_dir()}/../entra"
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

dependency "gateway" {
  config_path = "${get_terragrunt_dir()}/../gateway"
}

dependency "nodes" {
  config_path = "${get_terragrunt_dir()}/../nodes"
}

inputs = {
  kubeconfig                  = dependency.talos.outputs.kubeconfig
  forgejo_bucket              = dependency.storage.outputs.buckets["forgejo"]
  bucket_endpoint             = dependency.storage.outputs.bucket_endpoint

  oidc_url = dependency.entra.outputs.oidc_url
  application_credentials = dependency.entra.outputs.application_credentials
  groups = dependency.entra.outputs.groups

  smtp_host   = dependency.mail.outputs.smtp_host
  smtp_sender = dependency.mail.outputs.senders

  redis_host     = dependency.databases.outputs.redis_host
  redis_password = dependency.databases.outputs.redis_password

  public_loadbalancer_ip = dependency.cni.outputs.public_loadbalancer_ip

  ca_volume       = dependency.gateway.outputs.ca_volume
  ca_volume_mount = dependency.gateway.outputs.ca_volume_mount

  postgres_host            = dependency.databases.outputs.postgres_host
  postgres_databases       = dependency.databases.outputs.postgres_databases

  controlplane         = dependency.nodes.outputs.controlplane
}
