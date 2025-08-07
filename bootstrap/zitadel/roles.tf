resource "zitadel_project_role" "admin" {
  org_id     = local.zitadel_org
  project_id = zitadel_project.this.id

  role_key     = "admin"
  display_name = "Administrator"
}

resource "zitadel_project_role" "additional_roles" {
  for_each = var.additional_roles

  org_id     = local.zitadel_org
  project_id = zitadel_project.this.id

  role_key     = each.key
  display_name = each.value
}
