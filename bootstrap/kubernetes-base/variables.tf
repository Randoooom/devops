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

variable "backup_bucket_endpoint" {
  sensitive = true
  type      = string
}

variable "backup_bucket_name" {
  sensitive = true
  type      = string
}

variable "backup_bucket_access_key_id" {
  sensitive = true
  type      = string
}

variable "backup_bucket_secret_access_key" {
  sensitive = true
  type      = string
}
