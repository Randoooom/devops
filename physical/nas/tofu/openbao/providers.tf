terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "5.7.0"
    }
  }
}

provider "vault" {
  address = var.openbao_endpoint
  auth_login_userpass {
    username = var.openbao_username
    password = var.openbao_password
  }
}


