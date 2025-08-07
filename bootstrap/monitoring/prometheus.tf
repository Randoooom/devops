resource "kubernetes_secret" "thanos_credentials" {
  depends_on = [kubernetes_namespace.monitoring]

  metadata {
    name      = "thanos-credentials"
    namespace = "sys-monitoring"
  }

  data = {
    username = var.thanos_username
    password = var.thanos_password
  }
}

resource "helm_release" "prometheus" {
  depends_on = [kubernetes_namespace.monitoring]

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "75.18.1"

  namespace = "sys-monitoring"
  name      = "prometheus"

  values = [yamlencode({
    alertmanager = {
      enabled = false
    }

    grafana = {
      enabled = false
    }

    nodeExporter = {
      enabled = false
    }

    kubeScheduler = {
      enabled = false
    }

    kubeControllerManager = {
      enabled = false
    }

    kubeProxy = {
      enabled = false
    }

    prometheus = {
      prometheusSpec = {
        podMetadata = {
          labels = {
            wireguard = "true"
          }
        }
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
        probeSelectorNilUsesHelmValues          = false

        retention     = "3d"
        retentionSize = "3GB"

        remoteWrite = [
          {
            url = "${var.thanos_endpoint}"
            basicAuth = {
              username = {
                name = "thanos-credentials"
                key  = "username"
              }
              password = {
                name = "thanos-credentials"
                key  = "password"
              }
            }
          }
        ]
      }
    }
  })]
}
