variable "senders" {
  type = map(list(string))
}

variable "cloudflare_zone" {
  type = string
}

variable "compartment_ocid" {
  type      = string
  sensitive = true
}
