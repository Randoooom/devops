locals {
  users = [for host in var.backup_hosts : {
    name = host
    path = "host/${host}"
  }]
}

resource "scaleway_iam_application" "this" {
  for_each = { for user in local.users : user.name => user }
  name     = each.key
}

resource "scaleway_iam_api_key" "this" {
  for_each = scaleway_iam_application.this

  application_id = each.value.id
}

resource "scaleway_iam_policy" "this" {
  for_each = scaleway_iam_application.this

  name           = "policy-${each.key}"
  description    = "Access policy for ${each.key} to bucket ${var.bucket_name}"
  application_id = each.value.id

  rule {
    project_ids          = [var.scaleway_project_id]
    permission_set_names = ["ObjectStorageObjectsRead", "ObjectStorageObjectsWrite", "ObjectStorageObjectsDelete"]
  }
}

resource "scaleway_object_bucket_policy" "this" {
  bucket = var.bucket_name

  policy = jsonencode({
    Version = "2023-04-17"
    Statement = concat(
      [{
        Sid       = "AllowFullBucketAccess"
        Effect    = "Allow"
        Action    = "s3:*"
        Principal = { SCW = ["application_id:${var.scaleway_application_id}", "user_id:${var.scaleway_administrator}"] }
        Resource  = [var.bucket_name, "${var.bucket_name}/*"]
      }],
      [for user in local.users : {
        Sid       = "AllowUserPrefixAccess"
        Effect    = "Allow"
        Action    = ["s3:DeleteObject", "s3:GetObject", "s3:ListBucket", "s3:PutObject"]
        Principal = { SCW = "application_id:${scaleway_iam_application.this[user.name].id}" }
        Resource  = ["${var.bucket_name}/${user.path}*"]
      }]
    )
  })
}
