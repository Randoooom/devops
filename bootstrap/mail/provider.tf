terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.18.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.5"
    }
  }
}
