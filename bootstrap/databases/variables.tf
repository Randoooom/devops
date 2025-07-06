variable "cluster_domain" {
  type = string
}

variable "bucket_endpoint" {
  type      = string
  sensitive = true
}

variable "buckets" {
  type = map(object({
    id   = string,
    key  = string
    name = string
  }))
  sensitive = true
}

variable "postgres_databases" {
  type = map(string)
}
