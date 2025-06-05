terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "7.4.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.5"
    }
  }
}
