generate "entra" {
path       = "entra.tf"
if_exists  = "overwrite_terragrunt"
contents   = <<EOF
variable "azure_client_id" {
  type      = string
  sensitive = true
}

variable "azure_client_secret" {
  type      = string
  sensitive = true
}

variable "azure_tenant_id" {
  type      = string
  sensitive = true
}

provider "azuread" {
  client_id     = var.azure_client_id
  client_secret = var.azure_client_secret
  tenant_id     = var.azure_tenant_id
}
EOF
}
