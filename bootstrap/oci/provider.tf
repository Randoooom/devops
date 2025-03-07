terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.18.0"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.7.0-alpha.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key      = var.private_key
  fingerprint      = var.fingerprint
  region           = "eu-frankfurt-1"
}
