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
    redirect_uris           = list(string)
    logout_uris             = optional(list(string), [])
    required_roles          = list(string),
    app_role_assignment_req = optional(bool, false)
    sign_in_audience        = optional(string, "AzureADMyOrg")
  }))
}


variable "additional_groups" {
  type = list(string)
}
