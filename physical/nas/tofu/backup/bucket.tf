resource "scaleway_object_bucket" "this" {
  name = var.bucket_name

  versioning {
    enabled = false
  }

  lifecycle_rule {
    id      = "delete-incomplete"
    enabled = true

    abort_incomplete_multipart_upload_days = 1
  }

  dynamic "lifecycle_rule" {
    for_each = var.retentions

    content {
      id      = trimsuffix("retention-${replace(lifecycle_rule.key, "/", "-")}", "-")
      prefix  = lifecycle_rule.key
      enabled = true

      expiration {
        days = lifecycle_rule.value
      }
    }
  }
}
