resource "random_password" "bucket_user" {
  for_each = { for bucket in var.buckets : bucket.bucket => bucket }

  length  = 32
  special = false
}

resource "rustfs_bucket" "bucket" {
  for_each = { for bucket in var.buckets : bucket.bucket => bucket }

  name = each.value.bucket
}
resource "rustfs_policy" "bucket_policy" {
  depends_on = [rustfs_bucket.bucket]

  for_each = { for bucket in var.buckets : bucket.bucket => bucket }

  name = "${each.value.bucket}-policy"

  statement = [{
    effect = "Allow"
    action = ["s3:*"]
    ressource = [
      "arn:aws:s3:::${each.value.bucket}",
      "arn:aws:s3:::${each.value.bucket}/*"
    ]
  }]
}

resource "rustfs_user" "bucket_user" {
  depends_on = [rustfs_policy.bucket_policy]

  for_each = { for bucket in var.buckets : bucket.bucket => bucket }

  access_key = each.value.username
  secret_key = random_password.bucket_user[each.key].result
  policy     = rustfs_policy.bucket_policy[each.key].name
}
