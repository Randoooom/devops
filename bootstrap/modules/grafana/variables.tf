variable "cluster_name" {
  type = string
}

variable "grafana_cloud_access_policy_token" {
  type      = string
  sensitive = true
}

variable "zitadel_host" {
  type = string
}

variable "zitadel_project" {
  type = string
}

variable "zitadel_grafana_client_id" {
  type      = string
  sensitive = true
}

variable "zitadel_grafana_client_secret" {
  type      = string
  sensitive = true
}
