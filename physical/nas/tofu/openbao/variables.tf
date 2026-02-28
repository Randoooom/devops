variable "openbao_username" {
  type = string
}

variable "openbao_password" {
  type      = string
  sensitive = true
}

variable "openbao_endpoint" {
  type      = string
  sensitive = true
}

variable "backup_hosts" {
  type      = list(string)
  sensitive = true
}
