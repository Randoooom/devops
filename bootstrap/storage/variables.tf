variable "compartment_ocid" {
  type      = string
  sensitive = true
}

variable "buckets" {
  type = list(string)
}

variable "cluster_name" {
  type = string
}
