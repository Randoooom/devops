variable "rustfs_endpoint" {
  type      = string
  sensitive = true
}

variable "rustfs_access_key" {
  type      = string
  sensitive = true
}

variable "rustfs_secret_key" {
  type      = string
  sensitive = true
}

variable "buckets" {
  type = list(object({
    bucket   = string
    username = string
  }))
}
