terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "2.66.0"
    }
  }
}

provider "scaleway" {
  access_key      = var.scaleway_access_key
  secret_key      = var.scaleway_secret_key
  project_id      = var.scaleway_project_id
  region          = var.scaleway_region
  zone            = var.scaleway_zone
  organization_id = var.scaleway_organization_id
}
