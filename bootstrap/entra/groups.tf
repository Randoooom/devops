locals {
  groups = concat(var.additional_groups, ["admin", "forgejo", "argocd-admin", "argocd", "feedbackfusion"])

  app_role_group_pairs = flatten([
    for app_name, app_conf in local.additional_applications : [
      for role in try(app_conf.required_roles, []) : {
        app_name = app_name
        role     = role
        group    = role
      }
      if contains(local.groups, role)
    ]
  ])
}

resource "azuread_group" "this" {
  for_each = toset(local.groups)

  display_name     = each.key
  owners           = [data.azuread_client_config.this.object_id]
  security_enabled = true
}

resource "azuread_app_role_assignment" "from_required_roles" {
  for_each = {
    for pair in local.app_role_group_pairs :
    "${pair.app_name}-${pair.group}" => pair
  }

  principal_object_id = azuread_group.this[each.value.group].object_id
  resource_object_id  = azuread_service_principal.additional[each.value.app_name].object_id

  app_role_id = lookup(
    {
      for r in azuread_application.additional[each.value.app_name].app_role :
      r.value => r.id
    },
    each.value.role,
    null
  )
}

