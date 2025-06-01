generate "cloudflare_provider" {
path       = "cloudflare_provider.tf"
if_exists  = "overwrite_terragrunt"
contents   = <<EOF
variable "cloudflare_api_token" {
  type = string
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
EOF
}
