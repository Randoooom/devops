terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.18.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}
