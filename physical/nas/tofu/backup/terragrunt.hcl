include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  defaults = include.root.locals.defaults
}

inputs = local.defaults
