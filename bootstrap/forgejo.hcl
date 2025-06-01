generate "forgejo_provider" {
path       = "forgejo_provider.tf"
if_exists  = "overwrite_terragrunt"
contents   = <<EOF
variable "forgejo_username" {
  type = string
}

variable "forgejo_password" {
  type = string
}

variable "forgejo_host" {
  type = string  
}

provider "forgejo" {
  host = var.forgejo_host
  username = var.forgejo_username
  password = var.forgejo_password
}
EOF
}
