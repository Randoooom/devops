include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "oci" {
  path = find_in_parent_folders("oci.hcl")
}
