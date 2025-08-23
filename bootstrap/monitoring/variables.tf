variable "ca_volume" {
  type = any
}

variable "ca_volume_mount" {
  type = any
}

variable "cluster_name" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "new_relic_token" {
  type      = string
  sensitive = true
}

variable "new_relic_api_token" {
  type      = string
  sensitive = true
}

variable "new_relic_account_id" {
  type      = string
  sensitive = true
}

variable "new_relic_prometheus_endpoint" {
  type = string
}

variable "new_relic_otlp_endpoint" {
  type = string
}

variable "new_relic_admin" {
  type      = string
  sensitive = true
}
