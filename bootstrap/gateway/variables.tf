variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "acme_email" {
  type      = string
  sensitive = true
}

variable "cluster_domain" {
  type = string
}

variable "public_domain" {
  type = string
}

variable "public_loadbalancer_ip" {
  sensitive = true
  type      = string
}
