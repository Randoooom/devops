variable "cluster_domain" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "bucket_access_key_id" {
  type      = string
  sensitive = true
}

variable "bucket_secret_access_key" {
  type      = string
  sensitive = true
}

variable "bucket_name" {
  type = string
}

variable "bucket_endpoint" {
  type = string
}
