output "redis_password" {
  sensitive = true
  value     = random_password.dragonfly_password.result
}

output "redis_host" {
  sensitive = true
  value     = local.redis_domain
}
