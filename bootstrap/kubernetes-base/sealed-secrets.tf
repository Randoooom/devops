resource "helm_release" "sealed_secrets" {
  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  version    = "2.17.1"

  name      = "sealed-secrets-controller"
  namespace = "kube-system"
}
