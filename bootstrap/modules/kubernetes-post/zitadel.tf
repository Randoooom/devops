data "kubernetes_secret" "zitadel_machine" {
  metadata {
    name      = "terraform"
    namespace = "sys-zitadel" 
  }
}

module "zitadel" {
  source = "../zitadel"

  zitadel_host = "secure.${var.public_domain}"

  cluster_domain = var.cluster_domain
  cluster_name   = var.cluster_name

  domain      = var.public_domain
  zitadel_key = data.kubernetes_secret.zitadel_machine.data["terraform.json"]
}
