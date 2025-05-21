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

variable "zitadel_project" {
  type = string
}

variable "discord_webhook" {
  type      = string
  sensitive = true
}

variable "public_domain" {
  type = string
}

variable "loki_endpoint" {
  type = string
}

variable "loki_username" {
  type = string
}

variable "loki_password" {
  type      = string
  sensitive = true
}

variable "tempo_endpoint" {
  type = string
}

variable "tempo_username" {
  type = string
}

variable "tempo_password" {
  type      = string
  sensitive = true
}

variable "thanos_endpoint" {
  type = string
}

variable "thanos_username" {
  type = string
}

variable "thanos_password" {
  type      = string
  sensitive = true
}

variable "zitadel_admin_mail" {
  type = string
}

variable "zitadel_smtp_tls" {
  type = bool
}

variable "zitadel_smtp_host" {
  type = string
}

variable "zitadel_smtp_username" {
  type = string
}

variable "zitadel_smtp_password" {
  type = string
}

variable "zitadel_smtp_sender" {
  type = string
}
