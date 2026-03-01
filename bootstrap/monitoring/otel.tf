
locals {
  namespace = kubernetes_namespace.monitoring.metadata[0].name
}

resource "kubectl_manifest" "otel_agent_clusterrole" {
  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"
    metadata = {
      name = "otel-agent-collector"
    }
    rules = [
      {
        apiGroups = [""]
        resources = ["pods", "namespaces", "nodes", "endpoints", "services"]
        verbs     = ["get", "list", "watch"]
      },
      {
        apiGroups = [""]
        resources = ["nodes/stats", "nodes/proxy"]
        verbs     = ["get"]
      },
      {
        apiGroups = ["apps"]
        resources = ["replicasets", "deployments", "statefulsets", "daemonsets"]
        verbs     = ["get", "list", "watch"]
      }
    ]
  })
}

resource "kubectl_manifest" "otel_agent_clusterrolebinding" {
  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "otel-agent-collector"
    }
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "otel-agent-collector"
    }
    subjects = [
      {
        kind      = "ServiceAccount"
        name      = "otel-agent-collector"
        namespace = local.namespace
      }
    ]
  })
}

resource "kubectl_manifest" "otel_gateway_clusterrole" {
  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"
    metadata = {
      name = "otel-gateway-collector"
    }
    rules = [
      {
        apiGroups = [""]
        resources = ["pods", "namespaces", "nodes", "endpoints", "services"]
        verbs     = ["get", "list", "watch"]
      },
      {
        apiGroups = ["apps"]
        resources = ["replicasets", "deployments", "statefulsets", "daemonsets"]
        verbs     = ["get", "list", "watch"]
      },
      {
        apiGroups = ["discovery.k8s.io"]
        resources = ["endpointslices"]
        verbs     = ["get", "list", "watch"]
      }
    ]
  })
}

resource "kubectl_manifest" "otel_gateway_clusterrolebinding" {
  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "otel-gateway-collector"
    }
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "otel-gateway-collector"
    }
    subjects = [
      {
        kind      = "ServiceAccount"
        name      = "otel-gateway-collector"
        namespace = local.namespace
      }
    ]
  })
}

resource "kubectl_manifest" "otel_gateway_ta_clusterrole" {
  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"
    metadata = {
      name = "otel-gateway-targetallocator"
    }
    rules = [
      {
        apiGroups = [""]
        resources = ["namespaces", "pods", "nodes", "services", "endpoints", "secrets", "configmaps"]
        verbs     = ["get", "list", "watch"]
      },
      {
        apiGroups = ["apps"]
        resources = ["replicasets", "deployments", "statefulsets", "daemonsets"]
        verbs     = ["get", "list", "watch"]
      },
      {
        apiGroups = ["discovery.k8s.io"]
        resources = ["endpointslices"]
        verbs     = ["get", "list", "watch"]
      },
      {
        apiGroups = ["networking.k8s.io"]
        resources = ["ingresses"]
        verbs     = ["get", "list", "watch"]
      },
      {
        apiGroups = ["monitoring.coreos.com"]
        resources = ["servicemonitors", "podmonitors", "probes", "scrapeconfigs"]
        verbs     = ["get", "list", "watch"]
      },
      {
        apiGroups = ["opentelemetry.io"]
        resources = ["opentelemetrycollectors"]
        verbs     = ["get", "list", "watch"]
      }
    ]
  })
}

resource "kubectl_manifest" "otel_gateway_ta_clusterrolebinding" {
  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "otel-gateway-targetallocator"
    }
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "otel-gateway-targetallocator"
    }
    subjects = [
      {
        kind      = "ServiceAccount"
        name      = "otel-gateway-targetallocator"
        namespace = local.namespace
      }
    ]
  })
}

resource "kubectl_manifest" "otel_agent" {
  depends_on = [
    kubectl_manifest.otel_agent_clusterrole,
    kubectl_manifest.otel_agent_clusterrolebinding,
    kubectl_manifest.otel_gateway
  ]

  yaml_body = yamlencode({
    apiVersion = "opentelemetry.io/v1beta1"
    kind       = "OpenTelemetryCollector"
    metadata = {
      name      = "otel-agent"
      namespace = local.namespace
    }
    spec = {
      volumes      = [var.ca_volume]
      volumeMounts = [var.ca_volume_mount]
      mode         = "daemonset"
      tolerations = [
        {
          operator = "Exists"
          effect   = "NoSchedule"
        }
      ]
      env = [
        {
          name = "NODE_NAME"
          valueFrom = {
            fieldRef = {
              fieldPath = "spec.nodeName"
            }
          }
        },
        {
          name = "NODE_IP"
          valueFrom = {
            fieldRef = {
              fieldPath = "status.hostIP"
            }
          }
        }
      ]
      volumes = [
        {
          name = "varlogpods"
          hostPath = {
            path = "/var/log/pods"
          }
        },
        {
          name = "hostfs"
          hostPath = {
            path = "/"
          }
        }
      ]
      volumeMounts = [
        {
          name      = "varlogpods"
          mountPath = "/var/log/pods"
          readOnly  = true
        },
        {
          name             = "hostfs"
          mountPath        = "/hostfs"
          readOnly         = true
          mountPropagation = "HostToContainer"
        }
      ]
      config = {
        receivers = {
          otlp = {
            protocols = {
              grpc = {
                endpoint = "0.0.0.0:4317"
              }
              http = {
                endpoint = "0.0.0.0:4318"
              }
            }
          }
          hostmetrics = {
            collection_interval = "30s"
            root_path           = "/hostfs"
            scrapers = {
              cpu    = {}
              memory = {}
              disk   = {}
              filesystem = {
                exclude_mount_points = {
                  mount_points = ["/var/lib/longhorn.*", "/var/lib/kubelet.*"]
                  match_type   = "regexp"
                }
              }
              network = {}
              load    = {}
              system  = {}
              processes = {}
            }
          }
          kubeletstats = {
            collection_interval   = "30s"
            auth_type             = "serviceAccount"
            endpoint              = "https://$${env:NODE_IP}:10250"
            insecure_skip_verify  = true
            node                  = "$${env:K8S_NODE_NAME}"
            extra_metadata_labels = ["container.id", "k8s.volume.type"]
            metric_groups         = ["container", "pod", "node", "volume"]
            metrics = {
              "container.cpu.usage" = {
                enabled = true
              }
              "container.uptime" = {
                enabled = true
              }
              "k8s.container.cpu_limit_utilization" = {
                enabled = true
              }
              "k8s.container.cpu_request_utilization" = {
                enabled = true
              }
              "k8s.container.memory_limit_utilization" = {
                enabled = true
              }
              "k8s.container.memory_request_utilization" = {
                enabled = true
              }
              "k8s.node.cpu.usage" = {
                enabled = true
              }
              "k8s.node.uptime" = {
                enabled = true
              }
              "k8s.pod.cpu.usage" = {
                enabled = true
              }
              "k8s.pod.cpu_limit_utilization" = {
                enabled = true
              }
              "k8s.pod.cpu_request_utilization" = {
                enabled = true
              }
              "k8s.pod.memory_limit_utilization" = {
                enabled = true
              }
              "k8s.pod.memory_request_utilization" = {
                enabled = true
              }
              "k8s.pod.uptime" = {
                enabled = true
              }
            }
          }
          filelog = {
            include           = ["/var/log/pods/*/*/*.log"]
            include_file_path = true
            include_file_name = false
            start_at          = "end"
            operators = [
              {
                type = "container"
                id   = "container-parser"
              }
            ]
          }
        }
        processors = {
          memory_limiter = {
            check_interval  = "5s"
            limit_mib       = 512
            spike_limit_mib = 128
          }
          k8sattributes = {
            auth_type   = "serviceAccount"
            passthrough = false
            extract = {
              metadata = [
                "k8s.namespace.name",
                "k8s.pod.name",
                "k8s.pod.uid",
                "k8s.node.name",
                "k8s.deployment.name",
                "k8s.statefulset.name",
                "k8s.daemonset.name",
                "k8s.container.name"
              ]
            }
            pod_association = [
              {
                sources = [
                  {
                    from = "resource_attribute"
                    name = "k8s.pod.ip"
                  }
                ]
              },
              {
                sources = [
                  {
                    from = "resource_attribute"
                    name = "k8s.pod.uid"
                  }
                ]
              },
              {
                sources = [
                  {
                    from = "connection"
                  }
                ]
              }
            ]
          }
          "resource/node" = {
            attributes = [
              {
                key    = "k8s.node.name"
                value  = "$${env:K8S_NODE_NAME}"
                action = "upsert"
              }
            ]
          }
          "resource/cluster" = {
            attributes = [
              {
                key    = "k8s.cluster.name"
                value  = var.cluster_name
                action = "upsert"
              }
            ]
          }
          batch = {
            send_batch_size     = 1024
            timeout             = "5s"
            send_batch_max_size = 2048
          }
        }
        exporters = {
          otlp = {
            endpoint = "otel-gateway-collector.${local.namespace}.svc.cluster.local:4317"
            tls = {
              insecure = true
            }
          }
        }
        service = {
          pipelines = {
            metrics = {
              receivers  = ["hostmetrics", "kubeletstats", "otlp"]
              processors = ["memory_limiter", "k8sattributes", "resource/node", "resource/cluster", "batch"]
              exporters  = ["otlp"]
            }
            logs = {
              receivers  = ["filelog", "otlp"]
              processors = ["memory_limiter", "k8sattributes", "resource/node", "resource/cluster", "batch"]
              exporters  = ["otlp"]
            }
            traces = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "k8sattributes", "resource/node", "resource/cluster", "batch"]
              exporters  = ["otlp"]
            }
          }
        }
      }
    }
  })
}

resource "kubectl_manifest" "otel_gateway" {
  depends_on = [
    kubectl_manifest.otel_gateway_clusterrole,
    kubectl_manifest.otel_gateway_clusterrolebinding,
    kubectl_manifest.otel_gateway_ta_clusterrole,
    kubectl_manifest.otel_gateway_ta_clusterrolebinding
  ]

  yaml_body = yamlencode({
    apiVersion = "opentelemetry.io/v1beta1"
    kind       = "OpenTelemetryCollector"
    metadata = {
      name      = "otel-gateway"
      namespace = local.namespace
      labels = {
        wireguard = "true"
      }
    }
    spec = {
      image        = "otel/opentelemetry-collector-contrib:0.146.1"
      volumes      = [var.ca_volume]
      volumeMounts = [var.ca_volume_mount]
      mode         = "statefulset"
      replicas     = 2
      podLabels = {
        wireguard = "true"
      }
      targetAllocator = {
        enabled            = true
        allocationStrategy = "consistent-hashing"
        prometheusCR = {
          enabled                = true
          serviceMonitorSelector = {}
          podMonitorSelector     = {}
        }
      }
      config = {
        receivers = {
          postgresql = {
            endpoint            = "${var.postgres_host}:5432"
            collection_interval = "60s"
            username            = "signoz"
            password            = var.postgres_signoz_password

            tls = {
              insecure = false
            }

            metrics = {
              "postgresql.database.locks" = {
                enabled = true
              }

              "postgresql.deadlocks" = {
                enabled = true
              }

              "postgresql.sequential_scans" = {
                enabled = true
              }
            }
          }

          otlp = {
            protocols = {
              grpc = {
                endpoint = "0.0.0.0:4317"
              }
              http = {
                endpoint = "0.0.0.0:4318"
              }
            }
          }

          prometheus = {
            config = {
              scrape_configs = []
            }
          }
        }
        processors = {
          memory_limiter = {
            check_interval  = "5s"
            limit_mib       = 1024
            spike_limit_mib = 256
          }
          k8sattributes = {
            auth_type   = "serviceAccount"
            passthrough = false
            extract = {
              metadata = [
                "k8s.namespace.name",
                "k8s.pod.name",
                "k8s.pod.uid",
                "k8s.node.name",
                "k8s.deployment.name",
                "k8s.statefulset.name",
                "k8s.daemonset.name",
                "k8s.container.name"
              ]
            }
            pod_association = [
              {
                sources = [
                  {
                    from = "resource_attribute"
                    name = "k8s.pod.ip"
                  }
                ]
              },
              {
                sources = [
                  {
                    from = "resource_attribute"
                    name = "net.host.name"
                  }
                ]
              },
              {
                sources = [
                  {
                    from = "connection"
                  }
                ]
              }
            ]
          }
          "resource/clusterHost" = {
            attributes = [
              {
                key    = "host.name"
                value  = var.cluster_name
                action = "upsert"
              }
            ]
          }
          "resource/cluster" = {
            attributes = [
              {
                key    = "k8s.cluster.name"
                value  = var.cluster_name
                action = "upsert"
              }
            ]
          }
          batch = {
            send_batch_size     = 2048
            timeout             = "5s"
            send_batch_max_size = 4096
          }
        }
        exporters = {
          "otlp/backend" = {
            endpoint    = var.otel_grpc_endpoint
            compression = "zstd"
            tls = {
              insecure = false
            }
          }
        }
        service = {
          pipelines = {
            "metrics/postgresql" = {
              receivers  = ["postgresql"]
              processors = ["resource/cluster", "resource/clusterHost", "batch"]
              exporters  = ["otlp/backend"]
            }
            "metrics/prometheus" = {
              receivers  = ["prometheus"]
              processors = ["memory_limiter", "k8sattributes", "resource/cluster", "batch"]
              exporters  = ["otlp/backend"]
            }
            "metrics/forwarded" = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "resource/cluster", "batch"]
              exporters  = ["otlp/backend"]
            }
            logs = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "resource/cluster", "batch"]
              exporters  = ["otlp/backend"]
            }
            traces = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "resource/cluster", "batch"]
              exporters  = ["otlp/backend"]
            }
          }
        }
      }
    }
  })
}
