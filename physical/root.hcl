terraform {
  source = "."
}

locals {
  backend_sops_path = "${get_parent_terragrunt_dir()}/backend.sops.yaml"
  backend_config    = fileexists(local.backend_sops_path) ? yamldecode(sops_decrypt_file(local.backend_sops_path)) : {}
  unit_path         = path_relative_to_include()
  state_key         = trimsuffix(replace(local.unit_path, "/", "-"), "-")

  root_level   = "${get_parent_terragrunt_dir()}/tfvars.sops.yaml"
  parent_level = "${dirname(get_terragrunt_dir())}/tfvars.sops.yaml"
  unit_level   = "${get_terragrunt_dir()}/tfvars.sops.yaml"

  root_vars   = fileexists(local.root_level)   ? yamldecode(sops_decrypt_file(local.root_level))   : {}
  parent_vars = fileexists(local.parent_level) ? yamldecode(sops_decrypt_file(local.parent_level)) : {}
  unit_vars   = fileexists(local.unit_level)  ? yamldecode(sops_decrypt_file(local.unit_level))   : {}

  defaults = merge(local.root_vars, local.parent_vars, local.unit_vars)
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "${local.backend_config.bucket}"
    key            = "${local.backend_config.key_prefix}${local.state_key}.tfstate"
    region         = "${local.backend_config.region}"
    encrypt        = true
    dynamodb_table = "${local.backend_config.dynamodb_table}"
  }

  encryption {
    key_provider "pbkdf2" "this" {
      passphrase = "${local.backend_config.state_passphrase}"
    }
    method "aes_gcm" "this" {
      keys = key_provider.pbkdf2.this
    }
    state {
      method = method.aes_gcm.this
    }
  }
}
EOF
}
