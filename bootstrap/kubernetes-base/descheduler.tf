resource "helm_release" "descheduler" {
  repository = "https://kubernetes-sigs.github.io/descheduler"
  chart      = "descheduler"
  version    = "0.32.2"

  name      = "descheduler"
  namespace = "kube-system"

  values = [yamlencode({
    kind = "Deployment"
  })]
}
