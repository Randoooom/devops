resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "sys-argocd"
  }
}

resource "kubernetes_secret" "argocd" {
  metadata {
    name      = "argocd-zitadel"
    namespace = kubernetes_namespace.argocd.metadata[0].name

    labels = {
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    client-id     = module.zitadel.argocd_client_id
    client-secret = module.zitadel.argocd_client_secret
  }
}

resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd, kubernetes_secret.argocd]

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.7.7"

  namespace = "sys-argocd"
  name      = "argocd"

  values = [yamlencode({
    global = {
      domain = "argocd.internal.${var.cluster_domain}"
    }
    configs = {
      repositories = {
        docker-registry = {
          url       = "registry-1.docker.io"
          username  = "docker"
          password  = ""
          name      = "docker-registry"
          enableOci = "true"
          type      = "helm"
        }
      }
      params = {
        "server.insecure" = false
      }

      cm = {
        "oidc.config" = <<EOF
name: Zitadel
issuer: https://secure.${var.public_domain}
clientID: $argocd-zitadel:client-id 
clientSecret: $argocd-zitadel:client-secret
requestedScopes:
  - openid
  - profile
  - email
  - groups
EOF
        url           = "https://argocd.internal.${var.cluster_domain}"
      }

      rbac = {
        "policy.csv" = <<EOF
g, ${module.zitadel.zitadel_project}:admin, role:admin
EOF
      }
    }
    server = {
      ingress = {
        enabled          = true
        ingressClassName = "internal"
        annotations = {
          "cert-manager.io/cluster-issuer"               = "letsencrypt"
          "nginx.ingress.kubernetes.io/ssl-passthrough"  = true
          "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
        }
        tls = true
      }
    }
    dex = {
      enabled = false
    }
  })]
}

resource "kubectl_manifest" "argocd_project" {
  depends_on = [helm_release.argocd]

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name       = var.cluster_name
      namespace  = "sys-argocd"
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      destinations = [
        {
          namespace = "*"
          server    = "https://kubernetes.default.svc"
        }
      ]
      sourceRepos = ["*"]
      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
      namespaceResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
    }
  })
}

resource "kubectl_manifest" "argocd_app_of_apps" {
  depends_on = [kubectl_manifest.argocd_project]

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "gitops"
      namespace = "sys-argocd"
    }
    spec = {
      destination = {
        namespace = "sys-argocd"
        server    = "https://kubernetes.default.svc"
      }
      source = {
        repoURL        = "https://github.com/randoooom/devops"
        path           = "gitops"
        targetRevision = "main"

        helm = {
          values = <<EOF
project: ${var.cluster_name}
domain: ${var.public_domain}
clusterDomain: ${var.cluster_domain}
EOF
        }
      }
      project = var.cluster_name
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  })
}
