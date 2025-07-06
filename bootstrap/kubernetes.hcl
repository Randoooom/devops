generate "kubernetes_provider" {
  path      = "kubernetes_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "kubeconfig" {
  type = string
}

variable "controlplane" {
  type = list(any)
}

variable "vpn_connected" {
  type = bool
  default = false
}

provider "kubernetes" {
  host = "https://$${var.vpn_connected ? var.controlplane[0].private_ip : "localhost"}:6443"

  client_certificate     = base64decode(yamldecode(var.kubeconfig).users.0.user.client-certificate-data)
  client_key             = base64decode(yamldecode(var.kubeconfig).users.0.user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(var.kubeconfig).clusters.0.cluster.certificate-authority-data)
}

provider "helm" {
  kubernetes {
    host = "https://$${var.vpn_connected ? var.controlplane[0].private_ip : "localhost"}:6443"

    client_certificate     = base64decode(yamldecode(var.kubeconfig).users.0.user.client-certificate-data)
    client_key             = base64decode(yamldecode(var.kubeconfig).users.0.user.client-key-data)
    cluster_ca_certificate = base64decode(yamldecode(var.kubeconfig).clusters.0.cluster.certificate-authority-data)
  }
}

provider "kubectl" {
  host = "https://$${var.vpn_connected ? var.controlplane[0].private_ip : "localhost"}:6443"

  client_certificate     = base64decode(yamldecode(var.kubeconfig).users.0.user.client-certificate-data)
  client_key             = base64decode(yamldecode(var.kubeconfig).users.0.user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(var.kubeconfig).clusters.0.cluster.certificate-authority-data)
  load_config_file       = false
}
EOF
}

