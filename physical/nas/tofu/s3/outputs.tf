output "credentials" {
  sensitive = true
  value = {
    for bucket in var.buckets : bucket.bucket => {
      access_key = rustfs_user.bucket_user[bucket.bucket].access_key
      secret_key = random_password.bucket_user[bucket.bucket].result
    }
  }
}
