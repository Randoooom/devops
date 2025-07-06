variable "cluster_name" {
  type = string
}

variable "public_domain" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "oauth2_proxy_client_id" {
  type = string
}

variable "oauth2_proxy_client_secret" {
  type      = string
  sensitive = true
}

variable "argocd_client_id" {
  type = string
}

variable "argocd_client_secret" {
  type      = string
  sensitive = true
}

variable "zitadel_project" {
  type = string
}

variable "forgejo_admin" {
  type      = string
  sensitive = true
}

variable "forgejo_client_id" {
  type = string
}

variable "forgejo_client_secret" {
  type      = string
  sensitive = true
}

variable "compartment_ocid" {
  type      = string
  sensitive = true
}

variable "forgejo_bucket" {
  type      = map(any)
  sensitive = true
}

variable "bucket_endpoint" {
  type      = string
  sensitive = true
}

variable "smtp_host" {
  type = string
}

variable "smtp_sender" {
  type      = map(any)
  sensitive = true
}

variable "redis_host" {
  sensitive = true
  type      = string
}

variable "redis_password" {
  sensitive = true
  type      = string
}

variable "loadbalancer_ip" {
  sensitive = true
  type      = string
}

variable "ca_volume" {
  type = any
}

variable "ca_volume_mount" {
  type = any
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
