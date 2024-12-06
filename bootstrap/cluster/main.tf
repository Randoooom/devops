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
  worker_ips           = data.terraform_remote_state.oci.outputs.worker_ips
  controlplane_ips     = data.terraform_remote_state.oci.outputs.controlplane_ips
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

  zitadel_host = var.zitadel_host
  vault        = data.terraform_remote_state.oci.outputs.vault

  remote_wireguard_peer_cidr  = var.remote_wireguard_peer_cidr
  remote_wireguard_public_key = var.remote_wireguard_public_key
  remote_wireguard_host       = var.remote_wireguard_host
  remote_subnet_cidr          = var.remote_subnet_cidr
  remote_wireguard_cidr       = var.remote_wireguard_cidr
}
