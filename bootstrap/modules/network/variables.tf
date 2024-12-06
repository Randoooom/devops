variable "cluster_name" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "labels" {
  type = map(string)
}

variable "vcn_cidrs" {
  type = list(string)
}

variable "subnet_cidr" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "public_cidr" {
  type = string
}
