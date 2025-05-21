module "talos" {
  source = "../modules/talos"

  talos_version        = var.talos_version
  vcn_id               = data.terraform_remote_state.oci.outputs.vcn_id
  region               = var.region
  cluster_name         = var.cluster_name
  pod_subnet_block     = var.pod_subnet_block
  service_subnet_block = var.service_subnet_block
  talos_ccm_version    = var.talos_ccm_version
  oracle_ccm_version   = var.oracle_ccm_version
  kubernetes_version   = var.kubernetes_version
  worker               = data.terraform_remote_state.oci.outputs.worker
  controlplane         = data.terraform_remote_state.oci.outputs.controlplane
  compartment_ocid     = var.compartment_ocid
  security_list_id     = data.terraform_remote_state.oci.outputs.security_list_id
  subnet_id            = data.terraform_remote_state.oci.outputs.subnet_id
  public_subnet        = data.terraform_remote_state.oci.outputs.public_subnet
}

module "kubernetes" {
  source = "../modules/kubernetes"

  kubeconfig           = module.talos.kubeconfig
  subnet_cidr          = var.subnet_cidr
  public_subnet        = data.terraform_remote_state.oci.outputs.public_subnet
  public_subnet_cidr   = data.terraform_remote_state.oci.outputs.public_subnet_cidr
  private_subnet       = data.terraform_remote_state.oci.outputs.subnet_id
  cluster_domain       = var.cluster_domain
  compartment_id       = var.compartment_ocid
  cluster_name         = var.cluster_name
  region               = var.region
  cloudflare_api_token = var.cloudflare_api_token
  acme_email           = var.acme_email
  discord_webhook      = var.discord_webhook
  public_domain        = var.public_domain

  zitadel_host    = var.zitadel_host
  zitadel_project = data.terraform_remote_state.oci.outputs.zitadel_project
  vault           = data.terraform_remote_state.oci.outputs.vault

  remote_wireguard_peer_cidr  = var.remote_wireguard_peer_cidr
  remote_wireguard_public_key = var.remote_wireguard_public_key
  remote_wireguard_host       = var.remote_wireguard_host
  remote_subnet_cidr          = var.remote_subnet_cidr
  remote_wireguard_cidr       = var.remote_wireguard_cidr

  loki_endpoint = var.loki_endpoint
  loki_username = var.loki_username
  loki_password = var.loki_password

  tempo_endpoint = var.tempo_endpoint
  tempo_username = var.tempo_username
  tempo_password = var.tempo_password

  thanos_endpoint = var.thanos_endpoint
  thanos_username = var.thanos_username
  thanos_password = var.thanos_password

  zitadel_admin_mail    = var.zitadel_admin_mail
  zitadel_smtp_tls      = var.zitadel_smtp_tls
  zitadel_smtp_username = var.zitadel_smtp_username
  zitadel_smtp_password = var.zitadel_smtp_password
  zitadel_smtp_host     = var.zitadel_smtp_host
  zitadel_smtp_sender   = var.zitadel_smtp_sender
}
