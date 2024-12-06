resource "zitadel_project_role" "admin" {
  org_id     = var.zitadel_org
  project_id = zitadel_project.this.id

  role_key     = "admin"
  display_name = "Administrator"
}

resource "zitadel_project_role" "grafana_viewer" {
  org_id     = var.zitadel_org
  project_id = zitadel_project.this.id

  role_key     = "grafana-viewer"
  display_name = "Grafana Viewer"
  group        = "Monitoring"
}

resource "zitadel_project_role" "grafana_editor" {
  org_id     = var.zitadel_org
  project_id = zitadel_project.this.id

  role_key     = "grafana-editor"
  display_name = "Grafana Editor"
  group        = "Monitoring"
}

resource "zitadel_project_role" "prometheus" {
  org_id     = var.zitadel_org
  project_id = zitadel_project.this.id

  role_key     = "prometheus"
  display_name = "Prometheus"
  group        = "Monitoring"
}
