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
    NEW_RELIC_ACCOUNT_ID = var.new_relic_account_id
    NEW_RELIC_TOKEN      = var.new_relic_token
  }
}

resource "helm_release" "vector_agent" {
  repository = "https://helm.vector.dev"
  chart      = "vector"
  version    = "0.48.0"

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
.service.name = .app
.source = "vector"
.cluster_name = "${var.cluster_name}"
.pod_name = .kubernetes.pod_name
.node_name = .kubernetes.pod_node_name

.deployment_name = .kubernetes.pod_owner
if !exists(.deployment_name) || .deployment_name == "" {
  .deployment_name = .app
}

EOF
          }
        }

        sinks = {
          vector = {
            type    = "vector"
            address = "${local.aggregator_host}:6000"
            inputs  = ["parsed_logs", "otlp.traces", "otlp.metrics"]

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
  version    = "0.48.0"

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
              logs = {
                type = "is_log"
              }
              traces = {
                type = "is_trace"
              }
              metrics = {
                type = "is_metric"
              }
            }
          }
        }

        sinks = {
          new_relic_metrics = {
            type   = "new_relic"
            inputs = ["router.metrics"]

            account_id  = "'$${NEW_RELIC_ACCOUNT_ID}'"
            api         = "metrics"
            license_key = "$${NEW_RELIC_TOKEN}"
            region      = "eu"
            compression = "gzip"
          }

          new_relic_logs = {
            type   = "new_relic"
            inputs = ["router.logs"]

            account_id  = "'$${NEW_RELIC_ACCOUNT_ID}'"
            api         = "logs"
            license_key = "$${NEW_RELIC_TOKEN}"
            region      = "eu"
            compression = "gzip"
          }

          new_relic_traces = {
            type   = "opentelemetry"
            inputs = ["router.traces"]

            protocol = {
              uri  = var.new_relic_otlp_endpoint
              type = "http"

              encoding = {
                codec = "json"
              }

              auth = {
                strategy = "bearer"
                token    = "$${NEW_RELIC_TOKEN}"
              }
            }
          }
        }
      }
  }))]
}

resource "kubectl_manifest" "vector_aggregator_route" {
  depends_on = [helm_release.vector_aggregator]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "vector"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name        = "private"
          sectionName = "https"
          namespace   = "default"
        }
      ]
      hostnames = ["vector.internal.${var.cluster_domain}"]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = "vector-aggregator"
              port = 8686
            }
          ]
        }
      ]
    }
  })
}
