module "kubernetes_post" {
  source = "../modules/kubernetes-post"

  kubeconfig     =data.terraform_remote_state.cluster.outputs.kubeconfig 
  cluster_domain = var.cluster_domain
  cluster_name   = var.cluster_name
  public_domain  = var.public_domain
}
