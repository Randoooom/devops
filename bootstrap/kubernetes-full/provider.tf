terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.34.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }

    oci = {
      source  = "oracle/oci"
      version = "6.37.0"
    }
  }
}
