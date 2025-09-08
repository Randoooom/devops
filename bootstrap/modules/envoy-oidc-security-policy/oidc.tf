locals {
  identifier = "${var.cluster_name}-${var.route}"
}

module "entra" {
  source = "./entra"

  count = local.credentials_given ? 0 : 1

  applications = {
    (local.identifier) = {
      redirect_uris           = ["https://${var.hostname}/envoy/callback"]
      logout_uris             = ["https://${var.hostname}/envoy/logout"]
      required_roles          = [local.identifier]
      app_role_assignment_req = true
      sign_in_audience        = "AzureADMyOrg"
    }
  }
  groups = [local.identifier]
}
