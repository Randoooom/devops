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
  version    = "1.17.4"

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

    ingressController = {
      enabled           = true
      defaultSecretName = kubernetes_namespace.cilium.metadata[0].name
      loadbalancerMode  = "shared"

      service = {
        annotations = {
          "oci-network-load-balancer.oraclecloud.com/subnet"                        = var.public_subnet
          "oci.oraclecloud.com/load-balancer-type"                                  = "nlb"
          "oci-network-load-balancer.oraclecloud.com/security-list-management-mode" = "None"
          "external-dns.alpha.kubernetes.io/hostname"                               = "*.${var.cluster_domain}"
        }
      }
    }

    hubble = {
      enabled = true

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
