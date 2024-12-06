variable "kubeconfig" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "private_subnet" {
  type = string
}

variable "public_subnet" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "compartment_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "region" {
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

variable "vault" {
  type      = string
  sensitive = true
}

variable "public_subnet_cidr" {
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
