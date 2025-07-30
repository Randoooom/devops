terraform {
  extra_arguments "vars" {
    commands = [
      "apply",
      "plan",
      "import",
      "push",
      "refresh"
    ]

    arguments = [
      "-var-file=${get_terragrunt_dir()}/../.tfvars",
      "-var-file=${get_terragrunt_dir()}/.tfvars"
    ]
  }

  source = "."
}

generate "backend" {
  path       = "backend.tf"
  if_exists  = "overwrite_terragrunt"
  contents   = <<EOF
terraform {
  backend "s3" {
    bucket         = "${get_env("BACKEND_BUCKET")}"
    key            = "${get_env("BACKEND_PATH")}${path_relative_to_include()}/tf.tfstate"
    region         = "${get_env("BACKEND_REGION")}"
    encrypt        = true
    dynamodb_table = "${get_env("BACKEND_LOCK")}"
  }

  encryption {
    method "unencrypted" "migrate" {}

    key_provider "pbkdf2" "this" {
      passphrase = "${get_env("STATE_PASSPHRASE")}"
    }

    method "aes_gcm" "this" {
      keys = key_provider.pbkdf2.this
    }

    state {
      method = method.aes_gcm.this

      fallback {
        method = method.unencrypted.migrate
      }
    }
  }
}
EOF
}

generate "common" {
  path = "common_variables.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
variable "labels" {
  type = map(string)
}

variable "module_path" {
  type = string
}

variable "services" {
  type = map(object({
    port      = number
    node_port = number
    protocol  = string
  }))
}
  EOF
}

inputs = {
  module_path = "${get_terragrunt_dir()}/../modules"
}
