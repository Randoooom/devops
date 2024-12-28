resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info[*].name
        }
      }
    }
  )
}


resource "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on = [
    talos_machine_bootstrap.bootstrap
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = "talos:50001"
  node                 = var.controlplane[0].private_ip
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = zipmap(range(1, length(var.controlplane) + 1), var.controlplane)

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  endpoint                    = "talos:${50000 + each.key}"
  node                        = each.value.private_ip
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on = [talos_machine_bootstrap.bootstrap]
  for_each   = zipmap(range(1, length(var.worker) + 1), var.worker)

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  endpoint                    = "talos:${50001}"
  node                        = each.value.private_ip
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = "talos:50001"
  node                 = var.controlplane[0].private_ip

  lifecycle {
    ignore_changes = all
  }
}
