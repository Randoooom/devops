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
      type = "ClusterIP"
      annotations = {
        "external-dns.alpha.kubernetes.io/hostname" = "wg.${var.cluster_domain}"
      }
    }
    replicaCount = 1
    metrics = {
      enabled = true
    }
  })]
}
