
// 
// Authentication
//

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

// 
// Cluster 
//

variable "cluster_name" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "talos_image_oci_bucket_url" {
  type = string
}

variable "vcn_cidrs" {
  type = list(string)
}

variable "subnet_cidr" {
  type = string
}

variable "talos_version" {
  type = string
}

variable "public_cidr" {
  type = string
}

variable "zitadel_host" {
  type = string
}

variable "zitadel_org" {
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

variable "public_domain" {
  type = string
}
