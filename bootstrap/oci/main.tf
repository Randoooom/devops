locals {
  labels = {
    Cluster = var.cluster_name
  }
}

module "network" {
  source = "../modules/network"

  compartment_ocid = var.compartment_ocid
  tenancy_ocid     = var.tenancy_ocid
  cluster_name     = var.cluster_name
  vcn_cidrs        = var.vcn_cidrs
  subnet_cidr      = var.subnet_cidr
  labels           = local.labels
  public_cidr      = var.public_cidr
}

module "nodes" {
  source = "../modules/nodes"

  compartment_ocid           = var.compartment_ocid
  tenancy_ocid               = var.tenancy_ocid
  talos_version              = var.talos_version
  cluster_name               = var.cluster_name
  labels                     = local.labels
  talos_image_oci_bucket_url = var.talos_image_oci_bucket_url

  control_plane_count          = var.control_plane_count
  control_plane_ram            = var.control_plane_ram
  control_plane_ocpu           = var.control_plane_ocpu
  control_plane_security_group = module.network.control_plane_security_group

  worker_count          = var.worker_count
  worker_ocpu           = var.worker_ocpu
  worker_ram            = var.worker_ram
  worker_security_group = module.network.worker_security_group

  subnet         = module.network.subnet
}

module "zitadel" {
  source = "../modules/zitadel"

  zitadel_host = var.zitadel_host
  zitadel_org  = var.zitadel_org

  cluster_domain = var.cluster_domain
  cluster_name   = var.cluster_name
}

module "vault" {
  source = "../modules/vault"

  compartment_id = var.compartment_ocid
  cluster_name   = var.cluster_name

  oauth2_proxy_client_id     = module.zitadel.oauth2_proxy_client_id
  oauth2_proxy_client_secret = module.zitadel.oauth2_proxy_client_secret

  grafana_client_id     = module.zitadel.grafana_client_id
  grafana_client_secret = module.zitadel.grafana_client_secret

  argocd_client_id     = module.zitadel.argocd_client_id
  argocd_client_secret = module.zitadel.argocd_client_secret
}
