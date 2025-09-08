locals {
  gateways = {
    public = {
      services = var.public_services,
      hostnames = [
        {
          name  = "https",
          value = "*.${var.cluster_domain}"
        },
        {
          name  = "https-public",
          value = "*.${var.public_domain}"
        }
      ]
    },
    private = {
      hostnames = [
        {
          name  = "https"
          value = "*.internal.${var.cluster_domain}"
        }
      ]
    }
  }
}

resource "kubernetes_namespace" "gateway" {
  metadata {
    name = "sys-gateway"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "gateway" {
  depends_on = [kubectl_manifest.ingress_certificate]

  chart   = "oci://docker.io/envoyproxy/gateway-helm"
  version = "1.4.3"

  namespace = kubernetes_namespace.gateway.metadata[0].name
  name      = "envoy-gateway"
}

resource "kubectl_manifest" "gateway_class" {
  for_each = local.gateways

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "envoy-${each.key}"
    }
    spec = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
      parametersRef = {
        group     = "gateway.envoyproxy.io"
        kind      = "EnvoyProxy"
        name      = each.key
        namespace = kubernetes_namespace.gateway.metadata[0].name
      }
    }
  })
}

resource "kubectl_manifest" "envoy_proxy" {
  for_each = local.gateways

  yaml_body = yamlencode({
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyProxy"
    metadata = {
      name      = each.key
      namespace = kubernetes_namespace.gateway.metadata[0].name
    }
    spec = {
      extraArgs = [
        "--use-dynamic-base-id"
      ]

      provider = {
        type = "Kubernetes"
        kubernetes = {
          envoyDeployment = {
            replicas = 2
          }
          envoyService = {
            type = each.key == "public" ? "NodePort" : "ClusterIP"
            patch = {
              type = "StrategicMerge"
              value = {
                spec = {
                  ports = each.key == "public" ? [
                    {
                      name     = "http-${each.value.services.http.node_port}"
                      port     = each.value.services.http.node_port
                      nodePort = each.value.services.http.node_port
                      target   = each.value.services.http.node_port
                      protocol = "TCP"
                    },
                    {
                      name     = "https-${each.value.services.https.node_port}"
                      port     = each.value.services.https.node_port
                      nodePort = each.value.services.https.node_port
                      target   = each.value.services.https.node_port
                      protocol = "TCP"
                    }
                  ] : null
                }
                metadata = {
                  annotations = each.key == "private" ? {
                    "external-dns.alpha.kubernetes.io/hostname" = "*.internal.${var.cluster_domain}"
                  } : {}
                }
              }
            }
          }
        }
      }

      telemetry = {
        # metrics = {
        #   prometheus = {
        #     disable = true
        #   }
        #
        #   sinks = [
        #     {
        #       type = "OpenTelemetry"
        #       openTelemetry = {
        #         host = "vector-agent-headless.sys-monitoring.svc.cluster.local"
        #         port = 4317
        #       }
        #     }
        #   ]
        # }

        tracing = {
          samplingRate = 100
          provider = {
            host = "vector-agent-headless.sys-monitoring.svc.cluster.local"
            port = 4317
          }
        }
      }
    }
  })
}

resource "kubectl_manifest" "gateway" {
  depends_on = [kubectl_manifest.gateway_class]
  for_each   = local.gateways

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name = each.key
    }
    spec = {
      addresses = each.key == "public" ? [
        {
          type  = "IPAddress"
          value = var.public_loadbalancer_ip
        }
      ] : []
      gatewayClassName = "envoy-${each.key}"
      listeners = flatten([
        [{
          name     = "http"
          protocol = "HTTP"
          port     = each.key == "public" ? each.value.services.http.node_port : 80
        }],
        [for hostname in each.value.hostnames : {
          name     = hostname.name
          hostname = hostname.value
          protocol = "HTTPS"
          port     = each.key == "public" ? each.value.services.https.node_port : 443

          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }

          tls = {
            certificateRefs = [
              {
                name  = "gateway-tls"
                kind  = "Secret"
                group = ""
              }
            ]
          }
        }]
      ])
    }
  })
}

resource "kubectl_manifest" "gateway_https_redirect" {
  depends_on = [kubectl_manifest.gateway]
  for_each   = local.gateways

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "https-redirect-${each.key}"
    }
    spec = {
      parentRefs = [
        {
          name        = each.key
          sectionName = "http"
        }
      ]
      hostnames = [
        for hostname in each.value.hostnames : hostname.value
      ]
      rules = [
        {
          filters = [
            {
              type = "RequestRedirect"
              requestRedirect = {
                scheme     = "https"
                statusCode = 301
              }
            }
          ]
        }
      ]
    }
  })
}
