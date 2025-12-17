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
  version    = "1.18.5"

  namespace = kubernetes_namespace.cilium.metadata[0].name
  name      = "cilium"

  values = [yamlencode({
    ipam = {
      mode = "kubernetes"

      operator = {
        clusterPoolIPv4PodCIDRList = [var.pod_subnet_block]
      }
    }

    kubeProxyReplacement                = true
    kubeProxyReplacementHealthzBindAddr = "0.0.0.0:10256"

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
  })]
}

resource "kubectl_manifest" "hubble_route" {
  depends_on = [helm_release.cilium]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "hubble"
      namespace = kubernetes_namespace.cilium.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name        = "private"
          sectionName = "https"
          namespace   = "default"
        }
      ]
      hostnames = ["hubble.internal.${var.cluster_domain}"]
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
              name = "hubble-ui"
              port = 80
            }
          ]
        }
      ]
    }
  })
}

module "hubble-oidc" {
  source = "${var.module_path}/envoy-oidc-security-policy"

  cluster_name = var.cluster_name
  route        = "hubble"
  hostname     = "hubble.internal.${var.cluster_domain}"
  namespace    = kubernetes_namespace.cilium.metadata[0].name
}
