resource "helm_release" "sealed_secrets" {
  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  version    = "2.17.0"

  name      = "sealed-secrets"
  namespace = "kube-system"

  values = [yamlencode({
    fullnameOverride = "sealed-secrets-controller"
  })]
}
