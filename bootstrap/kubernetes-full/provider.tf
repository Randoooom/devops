terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }

    oci = {
      source  = "oracle/oci"
      version = "6.18.0"
    }
  }
}
