terraform {
  required_providers {
    rustfs = {
      source  = "registry.terraform.io/weinmann-emt/rustfs"
      version = "0.0.2"
    }
  }
}

provider "rustfs" {
  endpoint      = var.rustfs_endpoint
  access_key    = var.rustfs_access_key
  access_secret = var.rustfs_secret_key
  ssl           = true
  insecure      = false
}
