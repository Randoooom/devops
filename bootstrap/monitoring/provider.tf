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

    newrelic = {
      source  = "newrelic/newrelic"
      version = "3.66.0"
    }
  }
}

provider "newrelic" {
  account_id = var.new_relic_account_id
  api_key    = var.new_relic_api_token
  region     = "EU"
}
