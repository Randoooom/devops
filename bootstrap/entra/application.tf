locals {
  additional_applications = merge(
    {
      argocd = {
        redirect_uris           = ["https://argocd.internal.${var.cluster_domain}/auth/callback"]
        logout_uris             = []
        required_roles          = ["argocd"]
        app_role_assignment_req = true
        sign_in_audience        = "AzureADMyOrg"
      }
      feedback_fusion = {
        redirect_uris           = ["https://feedback-fusion.${var.public_domain}/auth/oidc/callback"]
        logout_uris             = []
        required_roles          = ["feedback-fusion"]
        app_role_assignment_req = true
        sign_in_audience        = "AzureADMyOrg"
      }
      forgejo = {
        redirect_uris           = ["https://git.${var.public_domain}/user/oauth2/entra/callback"]
        logout_uris             = []
        required_roles          = ["forgejo"]
        app_role_assignment_req = true
        sign_in_audience        = "AzureADMyOrg"
      }
    },
    var.additional_applications
  )
}

resource "azuread_application" "additional" {
  for_each     = local.additional_applications
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
      name                  = "groups"
      essential             = true
    }

    id_token {
      name                  = "groups"
      essential             = true
    }
  }
}

resource "azuread_service_principal" "additional" {
  for_each = local.additional_applications

  client_id                    = azuread_application.additional[each.key].client_id
  app_role_assignment_required = try(each.value.app_role_assignment_req, false)
}

resource "azuread_application_password" "additional" {
  for_each       = local.additional_applications
  application_id = azuread_application.additional[each.key].id
  display_name   = "ClientSecret"
}

