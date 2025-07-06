variable "public_subnet" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "acme_email" {
  type      = string
  sensitive = true
}

variable "worker" {
  type = any
}

variable "compartment_ocid" {
  type      = string
  sensitive = true
}

variable "cluster_name" {
  type = string
}

variable "vcn_id" {
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

variable "public_domain" {
  type = string
}
