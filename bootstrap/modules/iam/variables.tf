variable "groups" {
  type = map(object({
    users = list(object({
      name              = string
      customerSecretKey = bool,
      smtp              = bool
    }))
    policies = list(string)
  }))
}

variable "tenancy_ocid" {
  sensitive = true
  type      = string
}

variable "labels" {
  type = map(string)
}
