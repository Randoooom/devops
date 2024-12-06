variable "compartment_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "oauth2_proxy_client_id" {
  type      = string
  sensitive = true
}

variable "oauth2_proxy_client_secret" {
  type      = string
  sensitive = true
}

variable "grafana_client_id" {
  type      = string
  sensitive = true
}

variable "grafana_client_secret" {
  type      = string
  sensitive = true
}

variable "argocd_client_id" {
  type      = string
  sensitive = true
}

variable "argocd_client_secret" {
  type      = string
  sensitive = true
}
