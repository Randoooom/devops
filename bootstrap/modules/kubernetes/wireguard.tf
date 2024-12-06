locals {
  wireguard = <<EOF
[Interface]
Address = ${var.remote_wireguard_peer_cidr}
ListenPort = 51871
PostUp   = wg set wg0 private-key /etc/wireguard/privatekey && iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = ${var.remote_wireguard_public_key}
AllowedIPs = ${var.remote_subnet_cidr}, ${var.remote_wireguard_cidr}
Endpoint = ${var.remote_wireguard_host}
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
  version    = "0.26.0"

  name      = "wireguard"
  namespace = "sys-wireguard"

  values = [yamlencode({
    configSecretName    = "wireguard-endpoint"
    autoscaling = {
      enabled = false
    }
    service = {
      port = 51871
      type = "LoadBalancer"
      annotations = {
        "oci-network-load-balancer.oraclecloud.com/subnet"                        = var.public_subnet
        "oci-network-load-balancer.oraclecloud.com/security-list-management-mode" = "None"
        "oci.oraclecloud.com/load-balancer-type"                                  = "nlb",
        "external-dns.alpha.kubernetes.io/hostname"                               = "wg.${var.cluster_domain}"
        "external-dns.alpha.kubernetes.io/access"                                 = "public"
      }
    }
    replicaCount = 1
  })]
}
