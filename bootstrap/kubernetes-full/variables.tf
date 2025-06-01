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
