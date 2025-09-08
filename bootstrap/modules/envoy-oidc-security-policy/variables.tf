variable "client_id" {
  type     = string
  nullable = true
  default = null
}

variable "client_secret" {
  type      = string
  sensitive = true
  nullable  = true
  default = null
}

variable "route" {
  type = string
}

variable "hostname" {
  type = string
}

variable "issuer" {
  type = string
  nullable = true
  default = null
}

variable "namespace" {
  type = string
}

variable "cluster_name" {
  type = string
}
