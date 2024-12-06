data "talos_image_factory_extensions_versions" "this" {
  # get the latest talos version
  talos_version = var.talos_version
  filters = {
    names = var.talos_extensions
  }
}

data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "oracle"
  architecture  = "arm64"
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = ["https://talos:50001"]
  nodes                = concat(var.controlplane_ips, var.worker_ips)
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.controlplane_ips[0]}:6443"

  machine_type    = "controlplane"
  machine_secrets = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  docs     = false
  examples = false

  config_patches = [
    local.talos_base_configuration,
    <<-EOT
    machine:
      features:
        kubernetesTalosAPIAccess:
          enabled: true
          allowedRoles:
            - os:reader
          allowedKubernetesNamespaces:
            - kube-system
    EOT
    ,
    yamlencode({
      machine = {
        certSANs = concat(var.controlplane_ips, ["10.0.0.1"])
      }
      cluster = {
        apiServer = {
          certSANs = concat(var.controlplane_ips, ["10.0.0.1"])
        }
      }
    }),
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.controlplane_ips[0]}:6443"

  machine_type    = "worker"
  machine_secrets = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  docs     = false
  examples = false

  config_patches = [
    local.talos_base_configuration,
    <<EOF
machine:
   disks:
     - device: /dev/sdb
       partitions:
         - mountpoint: /var/lib/longhorn
   kubelet:
      extraMounts:
        - destination: /var/lib/longhorn
          type: bind
          source: /var/lib/longhorn
          options:
          - bind
          - rshared
          - rw
EOF
    ,
    yamlencode({
      machine = {
        certSANs = concat(var.controlplane_ips, ["10.0.0.1"])
      }
      cluster = {
        apiServer = {
          certSANs = concat(var.controlplane_ips, ["10.0.0.1"])
        }
      }
    }),
  ]
}
