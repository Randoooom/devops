generate "kubernetes_provider" {
path       = "kubernetes_provider.tf"
if_exists  = "overwrite_terragrunt"
contents   = <<EOF
variable "kubeconfig" {
  type = string
}

provider "kubernetes" {
  host = "https://localhost:6443"

  client_certificate     = base64decode(yamldecode(var.kubeconfig).users.0.user.client-certificate-data)
  client_key             = base64decode(yamldecode(var.kubeconfig).users.0.user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(var.kubeconfig).clusters.0.cluster.certificate-authority-data)
}

provider "helm" {
  kubernetes {
    host = "https://localhost:6443"

    client_certificate     = base64decode(yamldecode(var.kubeconfig).users.0.user.client-certificate-data)
    client_key             = base64decode(yamldecode(var.kubeconfig).users.0.user.client-key-data)
    cluster_ca_certificate = base64decode(yamldecode(var.kubeconfig).clusters.0.cluster.certificate-authority-data)
  }
}

provider "kubectl" {
  host = "https://localhost:6443"

  client_certificate     = base64decode(yamldecode(var.kubeconfig).users.0.user.client-certificate-data)
  client_key             = base64decode(yamldecode(var.kubeconfig).users.0.user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(var.kubeconfig).clusters.0.cluster.certificate-authority-data)
  load_config_file       = false
}
EOF
}
