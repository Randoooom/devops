variable "cluster_name" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "zitadel_host" {
  type = string
}

variable "domain" {
  type = string
}

variable "zitadel_key" {
  type      = string
  sensitive = true
}
