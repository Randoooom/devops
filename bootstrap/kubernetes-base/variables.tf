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

variable "public_subnet_cidr" {
  type = string
}

variable "public_domain" {
  type = string
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

variable "bucket_endpoint" {
  type      = string
  sensitive = true
}

variable "buckets" {
  type = map(object({
    id   = string,
    key  = string
    name = string
  }))
  sensitive = true
}

variable "loadbalancer_ip" {
  sensitive = true
  type      = string
}

variable "postgres_admin_password" {
  sensitive = true
  type      = string
}

variable "postgres_databases" {
  sensitive = true
  type = map(object({
    username = string
    password = string
  }))
}

variable "postgres_host" {
  type = string
}

variable "ca_volume" {
  type = any
}

variable "ca_volume_mount" {
  type = any
}
