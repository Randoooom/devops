terraform {
  required_providers {
    zitadel = {
      source  = "zitadel/zitadel"
      version = "2.0.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }
  }
}

data "kubernetes_secret" "zitadel_machine" {
  metadata {
    name      = "terraform"
    namespace = "sys-zitadel"
  }
}

provider "zitadel" {
  domain           = "secure.${var.public_domain}"
  jwt_profile_json = data.kubernetes_secret.zitadel_machine.data["terraform.json"]
}
