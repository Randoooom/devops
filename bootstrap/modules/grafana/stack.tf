resource "grafana_cloud_stack" "this" {
  provider = grafana.cloud

  name = var.cluster_name
  slug = replace(var.cluster_name, "-", "")
}


resource "grafana_cloud_stack_service_account" "this" {
  provider   = grafana.cloud
  stack_slug = grafana_cloud_stack.this.slug

  name        = var.cluster_name
  role        = "Admin"
  is_disabled = false
}

resource "grafana_cloud_stack_service_account_token" "this" {
  provider   = grafana.cloud
  stack_slug = grafana_cloud_stack.this.slug

  name               = "terraform"
  service_account_id = grafana_cloud_stack_service_account.this.id
}
