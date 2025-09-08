variable "applications" {
  type = map(object({
    redirect_uris           = list(string)
    logout_uris             = optional(list(string), [])
    required_roles          = list(string),
    app_role_assignment_req = optional(bool, false)
    sign_in_audience        = optional(string, "AzureADMyOrg")
  }))
}

variable "groups" {
  type = list(string)
}
