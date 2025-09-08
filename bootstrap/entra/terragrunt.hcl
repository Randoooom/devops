include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "entra" {
  path = find_in_parent_folders("entra.hcl")
}
