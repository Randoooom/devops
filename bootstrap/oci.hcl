generate "oci_provider" {
path       = "oci_provider.tf"
if_exists  = "overwrite_terragrunt"
contents   = <<EOF
variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "private_key" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "region" {
  type = string
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key      = var.private_key
  fingerprint      = var.fingerprint
  region           = var.region 
}
EOF
}
