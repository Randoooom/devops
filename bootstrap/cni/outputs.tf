output "loadbalancer_ip" {
  sensitive = true
  value     = local.loadbalancer_ip
}

output "ca_volume" {
  value = {
    name = "certificates"
    configMap = {
      name     = "cluster-authority"
      optional = false
      items = [
        {
          key  = "root-certs.pem"
          path = "root-certs.pem"
        }
      ]
    }
  }
}

output "ca_volume_mount" {
  value = {
    name      = "certificates"
    readOnly  = true
    mountPath = "/etc/ssl/certs/root-certs.pem"
    subPath   = "root-certs.pem"
  }
}

