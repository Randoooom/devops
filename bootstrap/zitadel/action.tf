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
            api.v1.claims.setClaim(claim.projectId + ':' + role, 'true');
        })
    })
    api.v1.claims.setClaim('groups', groups);
}
EOT
  timeout         = "10s"
  allowed_to_fail = true
}

resource "zitadel_trigger_actions" "roles" {
  for_each = toset(["TRIGGER_TYPE_PRE_ACCESS_TOKEN_CREATION", "TRIGGER_TYPE_PRE_USERINFO_CREATION"])

  org_id       = local.zitadel_org
  flow_type    = "FLOW_TYPE_CUSTOMISE_TOKEN"
  trigger_type = each.key
  action_ids   = [zitadel_action.roles.id]
}
