resource "zitadel_project_role" "admin" {
  org_id     = local.zitadel_org
  project_id = zitadel_project.this.id

  role_key     = "admin"
  display_name = "Administrator"
}
