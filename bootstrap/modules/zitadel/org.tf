locals {
  zitadel_org = data.zitadel_orgs.this.ids[0]
}

data "zitadel_orgs" "this" {
  name        = var.cluster_name
  name_method = "TEXT_QUERY_METHOD_EQUALS_IGNORE_CASE"

  state = "ORG_STATE_ACTIVE"
}
