variable "cluster_name" {
  type = string
}

variable "public_domain" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "forgejo_admin" {
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

variable "public_loadbalancer_ip" {
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

variable "application_credentials" {
  type = map(object({
    client_id     = string
    client_secret = string
  }))
  sensitive = true
}

variable "oidc_url" {
  type      = string
  sensitive = true
}

variable "groups" {
  type = map(string)
}
