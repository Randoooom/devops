locals {
  keep = [
    "container_network_receive_bytes",
    "container_network_transmit_bytes",
    "container_memory_usage",
    "container_memory_working_set_bytes",
    "container_memory_cache",
    "container_cpu",
    "container_oom_events_total",
    "node",
    "kube_pod",
    "kube_container_status",
    "kube_node_info",
    "nginx",
    "node_network_receive_bytes_total",
    "node_network_transmit_bytes_total",
    "wireguard_received_bytes_total",
    "wireguard_sent_bytes_total",
    "wireguard_latest_handshake_seconds",
    "wireguard_latest_handshake_delay_seconds",
    "container_oom_events_total",
    "container_network_receive_packets_dropped_total",
    "container_network_receive_errors_total"
  ]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "sys-monitoring"
  }
}

resource "kubernetes_secret" "grafana_prometheus_credentials" {
  depends_on = [kubernetes_namespace.monitoring]

  metadata {
    name      = "grafana-prometheus-credentials"
    namespace = "sys-monitoring"
  }

  data = {
    username = "2284583"
    password = var.grafana_prometheus_write_token
  }
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
    }
    alloy = {
      configMap = {
        content = <<EOF
otelcol.receiver.otlp "otlp_receiver" {
  grpc {
    endpoint = "0.0.0.0:4317"
  }

  output {
    traces = [otelcol.exporter.otlp.grafanacloud.input,]
  }
}

otelcol.exporter.otlp "grafanacloud" {
  client {
    endpoint = "tempo-prod-15-prod-us-west-0.grafana.net:443"
    auth = otelcol.auth.basic.grafanacloud.handler
  }
}

otelcol.auth.basic "grafanacloud" {
  username = "1132284"
  password = "${var.grafana_tempo_write_token}"
}

logging {
	level = "info"

	write_to = [loki.write.grafanacloud.receiver]
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

  forward_to = [loki.write.grafanacloud.receiver]
}

loki.write "grafanacloud" {
  endpoint {
    url = "https://logs-prod-021.grafana.net/loki/api/v1/push"

    basic_auth {
      username = "1137969"
      password = "${var.grafana_loki_write_token}"
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

resource "helm_release" "prometheus_operator" {
  depends_on = [kubernetes_namespace.monitoring, helm_release.ingress, kubernetes_secret.grafana_prometheus_credentials]

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "66.3.0"

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

    kubeEtcd = {
      enabled = false
    }

    kubeApiServer = {
      enabled = false
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
      ingress = {
        enabled          = true
        hosts            = ["prometheus.internal.${var.cluster_domain}"]
        ingressClassName = "internal"
      }

      prometheusSpec = {
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
        probeSelectorNilUsesHelmValues          = false

        overrides = {

        }

        remoteWrite = [
          {
            url = "https://prometheus-prod-36-prod-us-west-0.grafana.net/api/prom/push"
            basicAuth = {
              username = {
                name = "grafana-prometheus-credentials"
                key  = "username"
              }
              password = {
                name = "grafana-prometheus-credentials"
                key  = "password"
              }
            }
            writeRelabelConfigs = [
              {
                sourceLabels = ["__name__"]
                regex        = "(kube_pod_tolerations|node_namespace|node_network|kube_pod_status_phase|kube_pod_status_reason|kube_pod_status_scheduled|kube_pod_init).*"
                action       = "drop"
              },
              {
                sourceLabels = ["__name__"]
                regex        = "(${join("|", local.keep)}).*"
                action       = "keep"
              }
            ]
          }
        ]

        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "longhorn"
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = "10Gi"
                }
              }
            }
          }
        }
      }
    }
  })]
}

resource "helm_release" "blackbox_exporter" {
  depends_on = [kubernetes_namespace.monitoring]

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-blackbox-exporter"
  version    = "9.3.0"

  name      = "blackbox-exporter"
  namespace = "sys-monitoring"

  values = [yamlencode({
    serviceMonitor = {
      enabled = true
    }
    pod = {
      labels = {
        wireguard = "true"
      }
    }
  })]
}
