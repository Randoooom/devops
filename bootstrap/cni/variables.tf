variable "public_subnet" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "acme_email" {
  type      = string
  sensitive = true
}
