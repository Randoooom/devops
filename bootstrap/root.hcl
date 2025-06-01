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
  EOF
}

inputs = {
  module_path = "${get_terragrunt_dir()}/../modules"
}
