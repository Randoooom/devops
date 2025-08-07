locals {
  vector_common = {
    podLabels = {
      wireguard = "true"
    }

    podAnnotations = {
      "reloader.stakater.com/auto" = "true"
    }
  }

  aggregator_host = "vector-aggregator.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local"
  agent_host      = "vector-agent.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local"
}

resource "kubernetes_secret" "vector_credentials" {
  metadata {
    name      = "vector-credentials"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    THANOS_USER     = var.thanos_username
    THANOS_PASSWORD = var.thanos_password

    LOKI_USER     = var.loki_username
    LOKI_PASSWORD = var.loki_password

    TEMPO_USER     = var.tempo_username
    TEMPO_PASSWORD = var.tempo_password
  }
}

resource "helm_release" "vector_agent" {
  repository = "https://helm.vector.dev"
  chart      = "vector"
  version    = "0.44.0"

  namespace = kubernetes_namespace.monitoring.metadata[0].name
  name      = "vector-agent"

  values = [yamlencode(merge(
    local.vector_common,
    {
      extraVolumes      = [var.ca_volume]
      extraVolumeMounts = [var.ca_volume_mount]

      role = "Agent"
      tolerations = [
        {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        },
      ]

      env = [
        {
          name = "KUBERNETES_NODE"
          valueFrom = {
            fieldRef = {
              fieldPath = "spec.nodeName"
            }
          }
        }
      ]

      service = {
        ports = [
          {
            name     = "vector"
            port     = 6000
            protocol = "TCP"
          },
          {
            name     = "otlp-grpc"
            port     = 4317
            protocol = "TCP"
          },
          {
            name     = "otlp-http"
            port     = 4318
            protocol = "TCP"
          }
        ]
      }

      customConfig = {
        data_dir = "/vector-data"

        sources = {
          node = {
            type = "host_metrics"
          }

          logs = {
            type = "kubernetes_logs"
          }

          otlp = {
            type = "opentelemetry"

            grpc = {
              address = "0.0.0.0:4317"
            }

            http = {
              address = "0.0.0.0:4318"
            }
          }
        }

        transforms = {
          deduped_logs = {
            type   = "dedupe"
            inputs = ["logs"]
          }

          parsed_logs = {
            type   = "remap"
            inputs = ["deduped_logs"]

            source = <<EOF
parsed =  parse_json(.message) ??
            parse_logfmt(.message) ??
            parse_syslog(.message) ??
            parse_common_log(.message) ?? {}

. = merge!(., parsed)
.level = downcase(.level) ?? "info"

if match(to_string!(.message), r'.*(Error|error|err=|Err=).*') {
  .level = "error"
}

if is_string(.kubernetes.pod_labels.app) {
  if !exists(.kubernetes.pod_labels."app.kubernetes.io/name") {
    .kubernetes.pod_labels."app.kubernetes.io/name" = .kubernetes.pod_labels.app
  }

  del(.kubernetes.pod_labels.app)
}

.app = .kubernetes.pod_labels."app.kubernetes.io/name"
.source = "vector"
.cluster = "${var.cluster_name}"
EOF
          }

          labeled_metrics = {
            type   = "remap"
            inputs = ["node"]

            source = <<EOF
.tags.source = "vector"
.tags.host = "$${KUBERNETES_NODE}"
.tags.cluster = "${var.cluster_name}"
EOF
          }
        }

        sinks = {
          vector = {
            type    = "vector"
            address = "${local.aggregator_host}:6000"
            inputs  = ["labeled_metrics", "parsed_logs", "otlp.traces"]

            tls = {
              enabled = true
              ca_file = "/etc/ssl/certs/root-certs.pem"

              verify_certificate = true
              verify_hostname    = true
            }
          }
        }
      }
    }
  ))]
}

resource "kubectl_manifest" "vector_aggregator_certificate" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "vector-aggregator-tls"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
    }
    spec = {
      secretName = "vector-aggregator-tls"
      issuerRef = {
        name = "cluster-authority"
        kind = "ClusterIssuer"
      }
      commonName = local.aggregator_host
      dnsNames   = [local.aggregator_host]
    }
  })
}

resource "helm_release" "vector_aggregator" {
  depends_on = [kubectl_manifest.vector_aggregator_certificate]

  repository = "https://helm.vector.dev"
  chart      = "vector"
  version    = "0.44.0"

  namespace = kubernetes_namespace.monitoring.metadata[0].name
  name      = "vector-aggregator"

  values = [yamlencode(merge(
    local.vector_common,
    {
      extraVolumes = [
        var.ca_volume,
        {
          name = "source-certificate"
          secret = {
            secretName = "vector-aggregator-tls"
          }
        }
      ]
      extraVolumeMounts = [
        var.ca_volume_mount,
        {
          name      = "source-certificate"
          readOnly  = true
          mountPath = "/source/ssl"
        }
      ]

      role = "Aggregator"

      envFrom = [
        {
          secretRef = {
            name = kubernetes_secret.vector_credentials.metadata[0].name
          }
        }
      ]

      customConfig = {
        api = {
          enabled    = true
          address    = "0.0.0.0:8686"
          playground = false
        }

        sources = {
          vector = {
            type    = "vector"
            address = "0.0.0.0:6000"

            tls = {
              enabled  = true
              ca_file  = "/source/ssl/ca.crt"
              crt_file = "/source/ssl/tls.crt"
              key_file = "/source/ssl/tls.key"

              verify_certificate = false
            }
          }
        }

        transforms = {
          router = {
            type   = "route"
            inputs = ["vector"]

            route = {
              metrics = {
                type = "is_metric"
              }
              logs = {
                type = "is_log"
              }
              traces = {
                type = "is_trace"
              }
            }
          }
        }

        sinks = {
          thanos = {
            type     = "prometheus_remote_write"
            inputs   = ["router.metrics"]
            endpoint = var.thanos_endpoint

            auth = {
              strategy = "basic"

              user     = "$${THANOS_USER}"
              password = "$${THANOS_PASSWORD}"
            }

            healthcheck = {
              enabled = false
            }
          }

          loki = {
            type     = "loki"
            inputs   = ["router.logs"]
            endpoint = var.loki_endpoint

            auth = {
              strategy = "basic"

              user     = "$${LOKI_USER}"
              password = "$${LOKI_PASSWORD}"
            }

            encoding = {
              codec = "text"
            }

            labels = {
              cluster   = var.cluster_name
              source    = "vector"
              app       = "{{ \"{{\" }} .app {{ \"}}\" }}"
              level     = "{{ \"{{\" }} .level {{ \"}}\" }}"
              pod       = "{{ \"{{\" }} .kubernetes.pod_name {{ \"}}\" }}"
              container = "{{ \"{{\" }} .kubernetes.container_name {{ \"}}\" }}"
              namespace = "{{ \"{{\" }} .kubernetes.pod_namespace {{ \"}}\" }}"
            }

            compression = "gzip"

            healthcheck = {
              enabled = false
            }
          }

          tempo = {
            type   = "opentelemetry"
            inputs = ["router.traces"]

            protocol = {
              uri  = var.tempo_endpoint
              type = "http"

              encoding = {
                codec = "json"
              }

              auth = {
                strategy = "basic"

                user     = "$${TEMPO_USER}"
                password = "$${TEMPO_PASSWORD}"
              }
            }
          }
        }
      }

      ingress = {
        enabled   = true
        className = "internal"
        hosts = [
          {
            host = "vector.internal.${var.cluster_domain}"
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
                port = {
                  name   = "api"
                  number = 8686
                }
              }
            ]
          }
        ]

        annotations = {
          "external-dns.alpha.kubernetes.io/cloudflare-proxied" = "false"
        }
      }
  }))]
}
