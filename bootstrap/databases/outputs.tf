output "redis_password" {
  sensitive = true
  value     = random_password.dragonfly_password.result
}

output "redis_host" {
  value = local.redis_domain
}

output "postgres_databases" {
  sensitive = true
  value = {
    for database, user in var.postgres_databases : database => {
      username = user,
      password = random_password.postgres_user_password[user].result
    }
  }
}

output "postgres_host" {
  value = local.postgres_domain
}

output "postgres_admin_password" {
  sensitive = true
  value     = random_password.postgres_admin.result
}
