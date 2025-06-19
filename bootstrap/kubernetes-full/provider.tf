terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.0.1"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }

    oci = {
      source  = "oracle/oci"
      version = "7.5.0"
    }
  }
}
