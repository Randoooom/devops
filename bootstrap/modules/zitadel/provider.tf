terraform {
  required_providers {
    zitadel = {
      source = "zitadel/zitadel"
      version = "2.0.1"
    }
  }
}

provider "zitadel" {
  domain           = var.zitadel_host
  jwt_profile_file = "../.zitadel"
}
