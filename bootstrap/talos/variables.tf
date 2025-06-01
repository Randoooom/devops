variable "cluster_name" {
  type = string
}

variable "talos_version" {
  type = string
}

variable "controlplane" {
  type = list(object({ private_ip : string }))
}

variable "worker" {
  type = list(object({ private_ip : string }))
}

variable "talos_ccm_version" {
  type = string
}

variable "oracle_ccm_version" {
  type = string
}

variable "pod_subnet_block" {
  type = string
}

variable "service_subnet_block" {
  type = string
}

variable "region" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "vcn_id" {
  type = string
}

variable "talos_extensions" {
  type = set(string)
  default = [
    "util-linux-tools",
    "iscsi-tools",
  ]
}

variable "compartment_ocid" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_list_id" {
  type = string
}

variable "public_subnet" {
  type = string
}
