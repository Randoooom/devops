resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "sys-monitoring"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

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
  version    = "70.4.2"

  namespace = "sys-monitoring"
  name      = "prometheus"

  values = [yamlencode({
    kubeScheduler = {
      enabled = false
    }

    kubeControllerManager = {
      enabled = false
    }

    kubeProxy = {
      enabled = false
    }

    defaultRules = {
      rules = {
        node = false
      }
    }

    alertmanager = {
      config = {
        route = {
          receiver = "discord"
        }
        receivers = [
          {
            name = "discord"
            discord_configs = [
              {
                webhook_url = var.discord_webhook
              }
            ]
          },
          {
            name = "null"
          }
        ]
      }
    }

    grafana = {
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

        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "longhorn"
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = "4Gi"
                }
              }
            }
          }
        }
      }
    }
  })]
}

resource "helm_release" "alloy" {
  depends_on = [kubernetes_namespace.monitoring]

  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "0.11.0"

  namespace = "sys-monitoring"
  name      = "alloy"

  values = [yamlencode({
    controller = {
      tolerations = [
        {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        },
      ]

      podLabels = {
        wireguard = "true"
      }
    }

    alloy = {
      configMap = {
        content = <<EOF
otelcol.receiver.otlp "otlp_receiver" {
  grpc {
    endpoint = "0.0.0.0:4317"
  }

  output {
    traces = [otelcol.exporter.otlphttp.tempo.input,]
  }
}

otelcol.exporter.otlphttp "tempo" {
  client {
    endpoint = "${var.tempo_endpoint}"
    auth = otelcol.auth.basic.tempo.handler
  }
}

otelcol.auth.basic "tempo" {
  username = "${var.tempo_username}"
  password = "${var.tempo_password}"
}

logging {
	level = "info"

	write_to = [loki.write.loki.receiver]
}

// https://grafana.com/docs/alloy/latest/collect/logs-in-kubernetes/
// discovery.kubernetes allows you to find scrape targets from Kubernetes resources.
// It watches cluster state and ensures targets are continually synced with what is currently running in your cluster.
discovery.kubernetes "pod" {
  role = "pod"
}

// discovery.relabel rewrites the label set of the input targets by applying one or more relabeling rules.
// If no rules are defined, then the input targets are exported as-is.
discovery.relabel "pod_logs" {
  targets = discovery.kubernetes.pod.targets

  // Label creation - "namespace" field from "__meta_kubernetes_namespace"
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    action = "replace"
    target_label = "namespace"
  }

  // Label creation - "pod" field from "__meta_kubernetes_pod_name"
  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    action = "replace"
    target_label = "pod"
  }

  // Label creation - "container" field from "__meta_kubernetes_pod_container_name"
  rule {
    source_labels = ["__meta_kubernetes_pod_container_name"]
    action = "replace"
    target_label = "container"
  }

  // Label creation -  "app" field from "__meta_kubernetes_pod_label_app_kubernetes_io_name"
  rule {
    source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
    action = "replace"
    target_label = "app"
  }

  // Label creation -  "job" field from "__meta_kubernetes_namespace" and "__meta_kubernetes_pod_container_name"
  // Concatenate values __meta_kubernetes_namespace/__meta_kubernetes_pod_container_name
  rule {
    source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_container_name"]
    action = "replace"
    target_label = "job"
    separator = "/"
    replacement = "$1"
  }

  // Label creation - "container" field from "__meta_kubernetes_pod_uid" and "__meta_kubernetes_pod_container_name"
  // Concatenate values __meta_kubernetes_pod_uid/__meta_kubernetes_pod_container_name.log
  rule {
    source_labels = ["__meta_kubernetes_pod_uid", "__meta_kubernetes_pod_container_name"]
    action = "replace"
    target_label = "__path__"
    separator = "/"
    replacement = "/var/log/pods/*$1/*.log"
  }

  // Label creation -  "container_runtime" field from "__meta_kubernetes_pod_container_id"
  rule {
    source_labels = ["__meta_kubernetes_pod_container_id"]
    action = "replace"
    target_label = "container_runtime"
    regex = "^(\\S+):\\/\\/.+$"
    replacement = "$1"
  }
}

// loki.source.kubernetes tails logs from Kubernetes containers using the Kubernetes API.
loki.source.kubernetes "pod_logs" {
  targets    = discovery.relabel.pod_logs.output
  forward_to = [loki.process.pod_logs.receiver]
}

// loki.process receives log entries from other Loki components, applies one or more processing stages,
// and forwards the results to the list of receivers in the component's arguments.
loki.process "pod_logs" {
  stage.static_labels {
      values = {
        cluster = "${var.cluster_name}",
      }
  }

  forward_to = [loki.write.loki.receiver]
}

loki.write "loki" {
  endpoint {
    url = "${var.loki_endpoint}"

    basic_auth {
      username = "${var.loki_username}"
      password = "${var.loki_password}"
    }
  }
}
EOF
      }

      extraPorts = [
        {
          port       = 4317
          targetPort = 4317
          name       = "otlp"
          protocol   = "TCP"
        }
      ]
    }
  })]
}
