locals {
  role_trigger = {
    trigger   = ["TRIGGER_TYPE_PRE_ACCESS_TOKEN_CREATION", "TRIGGER_TYPE_PRE_USERINFO_CREATION"]
    flow_type = "FLOW_TYPE_CUSTOMISE_TOKEN"
  }
  merged_actions = merge(var.additional_actions, { flatRoles = local.role_trigger })

  flow_types = distinct([for _action, action_data in local.merged_actions : action_data.flow_type])
  triggers   = distinct(flatten([for _action, action_data in local.merged_actions : action_data.trigger]))

  action_triggers = {
    for flow in local.flow_types : flow => {
      for trigger in local.triggers : trigger =>
      [for action, action_data in local.merged_actions : (action == "flatRoles" ? zitadel_action.roles.id : zitadel_action.additional_actions[action].id) if contains(action_data.trigger, trigger)]
    }
  }
}

resource "zitadel_action" "roles" {
  org_id          = local.zitadel_org
  name            = "flatRoles"
  script          = <<EOT
function flatRoles(ctx, api) {
    if (ctx.v1.user.grants === undefined || ctx.v1.user.grants.count == 0) return;

    let groups = [];
    ctx.v1.user.grants.grants.forEach(claim => {
        claim.roles.forEach(role => {
            groups.push(claim.projectId + ':' + role);
            api.v1.claims.setClaim(claim.projectId + ':' + role, true);
        })
    })
    api.v1.claims.setClaim('groups', groups);
}
EOT
  timeout         = "10s"
  allowed_to_fail = true
}

resource "zitadel_action" "additional_actions" {
  for_each = var.additional_actions

  org_id = local.zitadel_org
  name   = each.key
  script = replace(each.value.script, "PROJECT", zitadel_project.this.id)

  timeout         = "10s"
  allowed_to_fail = each.value.can_fail
}

resource "zitadel_trigger_actions" "this" {
  for_each = { for idx, data in flatten([for flow, flow_data in local.action_triggers : [
    for trigger, action_ids in flow_data : {
      flow_type    = flow,
      trigger_type = trigger,
      action_ids   = action_ids
    }
  ]]) : idx => data }

  org_id       = local.zitadel_org
  flow_type    = each.value.flow_type
  trigger_type = each.value.trigger_type
  action_ids   = each.value.action_ids
}
