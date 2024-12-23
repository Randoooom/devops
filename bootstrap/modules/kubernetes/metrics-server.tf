resource "helm_release" "metrics_server" {
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.2"

  name      = "metrics-server"
  namespace = "kube-system"

  values = [yamlencode({
    hostNetwork = {
      enabled = true
    }
    containerPort = 11250
  })]
}
