resource "azuread_application" "this" {
  for_each     = var.applications
  display_name = each.key

  web {
    redirect_uris = each.value.redirect_uris
    logout_url    = try(each.value.logout_uris[0], null)
  }

  sign_in_audience        = try(each.value.sign_in_audience, "AzureADMyOrg")
  group_membership_claims = ["ApplicationGroup"]

  dynamic "app_role" {
    for_each = try(each.value.required_roles, [])

    content {
      allowed_member_types = ["User", "Application"]
      description          = "${app_role.value} role for ${each.key} application"
      display_name         = app_role.value
      id                   = uuidv5("dns", "${each.key}-${app_role.value}")
      value                = app_role.value
    }
  }

  optional_claims {
    access_token {
      name      = "groups"
      essential = true
    }

    id_token {
      name      = "groups"
      essential = true
    }
  }
}

resource "azuread_service_principal" "this" {
  for_each = var.applications

  client_id                    = azuread_application.this[each.key].client_id
  app_role_assignment_required = try(each.value.app_role_assignment_req, false)
}

resource "azuread_application_password" "this" {
  for_each       = var.applications
  application_id = azuread_application.this[each.key].id
  display_name   = "ClientSecret"
}

