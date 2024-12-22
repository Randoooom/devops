terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.18.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = "~/.oci/oci_api_key.pem"
  private_key      = var.private_key
  fingerprint      = var.fingerprint
  region           = "eu-frankfurt-1"
}
