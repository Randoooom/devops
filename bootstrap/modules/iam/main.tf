locals {
  users = merge(
    [
      for group_name, group in var.groups : {
        for user in group.users : "${group_name}-${user.name}" => user
      }
  ]...)

  group_user = merge([
    for group_name, group in var.groups : {
      for user in group.users : "${group_name}-${user.name}" => {
        group = group_name
        user  = user
      }
    }
  ]...)
}

resource "oci_identity_user" "this" {
  for_each = local.users

  compartment_id = var.tenancy_ocid
  description    = each.value.name
  name           = each.value.name

  freeform_tags = var.labels
}

resource "oci_identity_group" "this" {
  for_each = var.groups

  compartment_id = var.tenancy_ocid
  description    = each.key
  name           = each.key


  freeform_tags = var.labels
}

resource "oci_identity_policy" "this" {
  for_each = var.groups

  compartment_id = var.tenancy_ocid
  description    = each.key
  name           = each.key
  statements     = each.value.policies

  freeform_tags = var.labels
}

resource "oci_identity_user_group_membership" "this" {
  for_each = local.group_user

  group_id = oci_identity_group.this[each.value.group].id
  user_id  = oci_identity_user.this["${each.value.group}-${each.value.user.name}"].id
}

resource "oci_identity_customer_secret_key" "this" {
  for_each = {
    for key, user in local.users :
    key => user
    if user.customerSecretKey == true
  }

  display_name = each.key
  user_id      = oci_identity_user.this[each.key].id
}

resource "oci_identity_smtp_credential" "this" {
  for_each = {
    for key, user in local.users :
    key => user
    if user.smtp == true
  }

  description = "SMTP credentials ${each.key}"
  user_id     = oci_identity_user.this[each.key].id
}
