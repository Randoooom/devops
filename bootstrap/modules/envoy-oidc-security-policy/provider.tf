terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }
  }
}
