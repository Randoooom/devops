terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }

    oci = {
      source  = "oracle/oci"
      version = "7.13.0"
    }

    age = {
      source = "clementblaise/age"
      version = "0.1.1"
    }
  }
}
