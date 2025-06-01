terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.37.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.5"
    }
  }
}
