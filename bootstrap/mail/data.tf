data "cloudflare_zone" "this" {
  filter = {
    name = var.cloudflare_zone
  }
}
