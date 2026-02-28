variable "bucket_name" {
  type = string
}

variable "scaleway_access_key" {
  type      = string
  sensitive = true
}

variable "scaleway_secret_key" {
  type      = string
  sensitive = true
}

variable "scaleway_project_id" {
  type = string
}

variable "scaleway_region" {
  type = string
}

variable "scaleway_zone" {
  type = string
}

variable "scaleway_organization_id" {
  type = string
}

variable "scaleway_application_id" {
  type = string
}

variable "scaleway_administrator" {
  type = string
}

variable "retentions" {
  type = map(string)
}

variable "backup_hosts" {
  type = list(string)
}
