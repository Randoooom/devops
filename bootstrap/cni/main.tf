resource "kubernetes_namespace" "cilium" {
  metadata {
    name = "sys-cilium"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "cilium" {
  depends_on = [kubernetes_namespace.cilium]

  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = "1.17.5"

  namespace = kubernetes_namespace.cilium.metadata[0].name
  name      = "cilium"

  values = [yamlencode({
    ipam = {
      mode = "kubernetes"
    }

    kubeProxyReplacement = true

    securityContext = {
      capabilities = {
        ciliumAgent      = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
        cleanCiliumState = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
      }
    }

    cgroup = {
      autoMount = {
        enabled = false
      }
      hostRoot = "/sys/fs/cgroup"
    }

    k8sServiceHost = "localhost"
    k8sServicePort = 7445

    bpf = {
      masquerade          = true
      lbExternalClusterIP = true
    }

    egressGateway = {
      enabled = true
    }

    kubeProxyReplacementHealthzBindAddr = "0.0.0.0:10256"

    encryption = {
      enabled        = true
      nodeEncryption = true
      type           = "wireguard"

      wireguard = {
        persistentKeepalive = "30s"
      }
    }

    operator = {
      prometheus = {
        serviceMonitor = {
          enabled = true
        }
      }
    }

    prometheus = {
      serviceMonitor = {
        enabled        = true
        trustCRDsExist = true
      }
    }

    envoy = {
      prometheus = {
        serviceMonitor = {
          enabled = true
        }
      }
    }

    hubble = {
      enabled = true

      relay = {
        enabled = true
      }

      ui = {
        enabled = true

        ingress = {
          className = "internal"
          enabled   = true
          hosts     = ["hubble.internal.${var.cluster_domain}"]
          annotations = {
            "external-dns.alpha.kubernetes.io/cloudflare-proxied" = "false"
          }
        }
      }

      metrics = {
        enabled = [
          "dns:query;ignoreAAAA",
          "drop",
          "tcp",
          "flow",
          "icmp",
          "http"
        ]

        serviceMonitor = {
          enabled = true
        }
      }
    }

    gatewayAPI = {
      enabled    = true
      enableAlpn = true
      hostNetwork = {
        enabled = true
      }
    }
  })]
}

resource "kubectl_manifest" "cilium_gateway" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name = "cilium"
      annotations = {
        "cert-manager.io/cluster-issuer"          = "letsencrypt"
        "external-dns.alpha.kubernetes.io/target" = local.loadbalancer_ip
      }
    }
    spec = {
      gatewayClassName = "cilium"
      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = var.services.http.node_port
        },
        {
          name     = "https"
          protocol = "HTTPS"
          port     = var.services.https.node_port
          hostname = "*.${var.cluster_domain}"

          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }

          tls = {
            certificateRefs = [
              {
                name  = "gateway-cluster-tls"
                kind  = "Secret"
                group = ""
              }
            ]
          }
        },
        {
          name     = "https-public"
          protocol = "HTTPS"
          port     = var.services.https.node_port
          hostname = "*.${var.public_domain}"

          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }

          tls = {
            certificateRefs = [
              {
                name  = "gateway-public-tls"
                kind  = "Secret"
                group = ""
              }
            ]
          }
        }
      ]
    }
  })
}

resource "kubectl_manifest" "gateway_https_redirect" {
  depends_on = [kubectl_manifest.cilium_gateway]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "https-redirect"
    }
    spec = {
      parentRefs = [
        {
          name        = "cilium"
          sectionName = "http"
        }
      ]
      hostnames = [
        "*.${var.cluster_domain}",
        "*.${var.public_domain}"
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
