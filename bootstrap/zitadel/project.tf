resource "zitadel_project" "this" {
  org_id = local.zitadel_org

  name = var.cluster_name

  has_project_check      = true
  project_role_assertion = true
}
