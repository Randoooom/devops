locals {
  metrics_to_ignore = [
    "rest_client_rate_limiter_duration",
    "rest_client_response_size",
    "rest_client_request_size",
    "container_blkio",
    "container_memory_failures",
    "container_fs_writes",
    "container_fs_reads",
    "container_network_transmit_bytes",
    "container_network_receive_bytes",
    "apiserver_flowcontrol_priority_level",
    "coredns_proxy_request_duration_seconds",
    "coredns_dns_request_duration_seconds",
    "rest_client_request_duration",
    "envoy_listener_downstream_cx_length_ms",
    "envoy_listener_connections_accepted_per_socket",
    "envoy_http_downstream_cx_length_ms"
  ]
}

resource "helm_release" "newrelic_bundle" {
  name      = "newrelic"
  namespace = kubernetes_namespace.monitoring.metadata[0].name

  chart      = "nri-bundle"
  repository = "https://helm-charts.newrelic.com"

  values = [yamlencode({
    global = {
      licenseKey  = var.new_relic_token
      cluster     = var.cluster_name
      lowDataMode = true
    }

    kube-state-metrics = {
      enabled = true
      image = {
        tag = "v2.13.0"
      }
    }

    kubeEvents = {
      enabled = true
    }

    newrelic-prometheus-agent = {
      enabled     = true
      lowDataMode = true

      config = {
        kubernetes = {
          integrations_filter = {
            enabled = false
          }
        }

        newrelic_remote_write = {
          extra_write_relabel_configs = [
            {
              source_labels = ["__name__"]
              regex         = "(${join("|", local.metrics_to_ignore)}).*"
              action        = "drop"
            }
          ]
        }
      }
    }

    logging = {
      enabled = false
    }

    newrelic-infrastructure = {
      controlPlane = {
        tolerations = [
          {
            key      = "node-role.kubernetes.io/control-plane"
            operator = "Exists"
            effect   = "NoSchedule"
          },
        ]

        resources = {
          requests = {
            cpu = "10m"
          }
        }
      }

      kubelet = {
        resources = {
          requests = {
            cpu = "10m"
          }
        }
      }
    }
  })]
}
