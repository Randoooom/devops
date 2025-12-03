locals {
  wireguard = <<EOF
[Interface]
Address = ${var.remote_wireguard_peer_cidr}
ListenPort = 51820
PostUp = wg set wg0 private-key /etc/wireguard/privatekey; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o cilium_host -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; iptables -t nat -D POSTROUTING -o cilium_host -j MASQUERADE


[Peer]
PublicKey = ${var.remote_wireguard_public_key}
AllowedIPs = ${var.remote_subnet_cidr}, ${var.remote_wireguard_cidr}
PersistentKeepAlive = 25
EOF
}

resource "kubernetes_namespace" "wireguard" {
  metadata {
    name = "sys-wireguard"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "kubernetes_secret" "wireguard" {
  depends_on = [kubernetes_namespace.wireguard]

  metadata {
    name      = "wireguard-endpoint"
    namespace = "sys-wireguard"
  }

  data = {
    "wg0.conf" = local.wireguard
  }
}

resource "helm_release" "wireguard" {
  depends_on = [kubernetes_secret.wireguard]

  repository = "https://bryopsida.github.io/wireguard-chart"
  chart      = "wireguard"
  version    = "0.31.0"

  name      = "wireguard"
  namespace = "sys-wireguard"

  values = [yamlencode({
    image = {
      tag        = "20240902-9c85c2e"
      pullPolicy = "IfNotPresent"
    }
    configSecretName = "wireguard-endpoint"
    autoscaling = {
      enabled = false
    }
    service = {
      port = 51871
      type = "LoadBalancer"
      annotations = {
        "oci.oraclecloud.com/load-balancer-type"                                  = "nlb"
        "oci-network-load-balancer.oraclecloud.com/security-list-management-mode" = "None"
        "oci-network-load-balancer.oraclecloud.com/subnet"                        = var.public_subnet
        "external-dns.alpha.kubernetes.io/hostname"                               = "wg.${var.cluster_domain}"
        "external-dns.alpha.kubernetes.io/cloudflare-proxied"                     = "false"
        // "external-dns.alpha.kubernetes.io/target"                                 = var.loadbalancer_ip
      }
    }
    metrics = {
      enabled = true
    }
    replicaCount = 1
    tolerations = [
      {
        key      = "node-role.kubernetes.io/control-plane"
        operator = "Exists"
        effect   = "NoSchedule"
      },
    ]
    runPodOnHostNetwork = true
    deploymentStrategy = {
      type = "Recreate"
    }
    affinity = {
      nodeAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = {
          nodeSelectorTerms = [
            {
              matchExpressions = [
                {
                  key      = "kubernetes.io/hostname"
                  operator = "In"
                  values = [
                    "${var.cluster_name}-controlplane-0"
                  ]
                }
              ]
            }
          ]
        }
      }
    }
  })]
}

resource "kubectl_manifest" "wireguard_egress" {
  yaml_body = yamlencode({
    apiVersion = "cilium.io/v2"
    kind       = "CiliumEgressGatewayPolicy"
    metadata = {
      name = "wireguard"
    }
    spec = {
      selectors = [
        {
          podSelector = {
            matchLabels = {
              wireguard = "true"
            }
          }
        },
        {
          podSelector = {
            matchLabels = {
              app = "csi-snapshotter"
            }
          }
        },
        {
          podSelector = {
            matchLabels = {
              "app" = "longhorn-manager"
            }
          }
        },
        {
          podSelector = {
            matchLabels = {
              "longhorn.io/component" = "instance-manager"
            }
          }
        }
      ]
      destinationCIDRs = [var.remote_subnet_cidr]
      egressGateway = {
        nodeSelector = {
          matchLabels = {
            "kubernetes.io/hostname" = "${var.cluster_name}-controlplane-0"
          }
        }
      }

    }
  })
}
