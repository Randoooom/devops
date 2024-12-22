variable "user_ocid" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "private_key" {
  type     = string
  default  = null
  nullable = true
}

variable "region" {
  type = string
}

variable "bastion_ssh_public_key" {
  type = string
}

variable "cluster_name" {
  type = string
}
