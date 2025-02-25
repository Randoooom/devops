// 
// Cluster 
//

variable "cluster_name" {
  type = string
}

variable "talos_version" {
  type = string
}

variable "region" {
  type = string
}

variable "pod_subnet_block" {
  type = string
}

variable "service_subnet_block" {
  type = string
}

variable "talos_ccm_version" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "oracle_ccm_version" {
  type = string
}

variable "compartment_ocid" {
  type = string
}
variable "subnet_cidr" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "private_key" {
  type     = string
  default  = null
  nullable = true
}

variable "cluster_domain" {
  type = string
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "acme_email" {
  type = string
}

variable "zitadel_host" {
  type = string
}

variable "remote_wireguard_host" {
  type = string
}

variable "remote_wireguard_public_key" {
  type = string
}

variable "remote_subnet_cidr" {
  type = string
}

variable "remote_wireguard_peer_cidr" {
  type = string
}

variable "remote_wireguard_cidr" {
  type = string
}

variable "discord_webhook" {
  type      = string
  sensitive = true
}

variable "public_domain" {
  type = string
}

variable "grafana_cloud_access_policy_token" {
  type      = string
  sensitive = true
}

variable "grafana_prometheus_write_token" {
  type      = string
  sensitive = true
}

variable "grafana_tempo_write_token" {
  type      = string
  sensitive = true
}

variable "grafana_loki_write_token" {
  type      = string
  sensitive = true
}
