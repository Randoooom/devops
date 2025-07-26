variable "cluster_name" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "public_domain" {
  type = string
}

variable "additional_applications" {
  type = map(object({
    redirect_uris             = list(string)
    response_types            = list(string)
    grant_types               = list(string)
    post_logout_redirect_uris = list(string)
    app_type                  = string
  }))
}
