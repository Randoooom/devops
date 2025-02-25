locals {
  folders = ["node", "nginx", "vpn", "kubernetes"]

  dashboards = flatten([
    for key in local.folders : [
      for file in fileset("${path.module}/dashboards/${key}", "*.json"): {
        key: key,
        file: file
      }
    ]
  ])
}

resource "grafana_folder" "this" {
  for_each = { for name in local.folders : name => "" }

  provider = grafana.stack

  title = each.key
}

resource "grafana_dashboard" "this" {
  for_each = { for dashboard in local.dashboards: dashboard.key => dashboard.file }

  provider = grafana.stack
  
  folder = grafana_folder.this[each.key].uid
  config_json = file("${path.module}/dashboards/${each.key}/${each.value}")
}
