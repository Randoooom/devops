locals {
  repositories = flatten([
    for org, data in var.organizations : [
      for repo, branch in data.mirrors : {
        organization = org
        repository   = repo
        name         = regex("([^/]+)\\.git$", repo)[0]
        branch       = branch
      }
    ]
  ])
}

resource "forgejo_organization" "this" {
  for_each = var.organizations

  name       = each.key
  visibility = each.value.public ? "public" : "limited"
}

resource "forgejo_repository" "this" {
  for_each = { for idx, repository in local.repositories : idx => repository }

  name  = each.value.name
  owner = forgejo_organization.this[each.value.organization].name

  mirror          = true
  clone_addr      = each.value.repository
  mirror_interval = "24h0m0s"
  auth_token      = var.access_tokens[regex("https?://([^/]+)", each.value.repository)[0]]
  default_branch = each.value.branch
}
