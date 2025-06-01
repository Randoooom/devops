variable "cluster_name" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "talos_image_oci_bucket_url" {
  type = string
}

variable "talos_version" {
  type = string
}

variable "control_plane_count" {
  type = number
}

variable "control_plane_ocpu" {
  type = number
}

variable "control_plane_ram" {
  type = number
}

variable "worker_count" {
  type = number
}

variable "worker_ocpu" {
  type = number
}

variable "worker_ram" {
  type = number
}

variable "subnet" {
  type = string
}

variable "control_plane_security_group" {
  type = string
}

variable "worker_security_group" {
  type = string
}
