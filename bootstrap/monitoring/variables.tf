variable "loki_endpoint" {
  type = string
}

variable "loki_username" {
  type = string
}

variable "loki_password" {
  type      = string
  sensitive = true
}

variable "tempo_endpoint" {
  type = string
}

variable "tempo_username" {
  type = string
}

variable "tempo_password" {
  type      = string
  sensitive = true
}

variable "thanos_endpoint" {
  type = string
}

variable "thanos_username" {
  type = string
}

variable "thanos_password" {
  type      = string
  sensitive = true
}

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
