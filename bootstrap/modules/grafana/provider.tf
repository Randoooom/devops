terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "3.20.0"
    }
  }
}

provider "grafana" {
  alias = "cloud"

  cloud_access_policy_token = var.grafana_cloud_access_policy_token
}

provider "grafana" {
  alias = "stack"

  url  = grafana_cloud_stack.this.url
  auth = grafana_cloud_stack_service_account_token.this.key
}
