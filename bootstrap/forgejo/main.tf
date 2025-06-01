locals {
  repositories = flatten([
    for org, data in var.organizations : [
      for repo in data.mirrors : {
        organization = org
        repository   = repo
      }
    ]
  ])
}

resource "forgejo_organization" "this" {
  for_each = var.organizations

  name       = each.key
  visibility = each.value.public ? "public" : "limited"
}

# https://github.com/svalabs/terraform-provider-forgejo/issues/25
# resource "forgejo_repository" "this" {
#   for_each = toset(local.repositories)
#
#   name  = each.key.repository
#   owner = forgejo_repository.this[each.key.organization].name
# }
