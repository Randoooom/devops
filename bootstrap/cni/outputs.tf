output "public_loadbalancer_ip" {
  sensitive = true
  value     = local.public_loadbalancer_ip
}
