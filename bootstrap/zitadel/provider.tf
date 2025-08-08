terraform {
  required_providers {
    zitadel = {
      source  = "zitadel/zitadel"
      version = "2.2.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
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
