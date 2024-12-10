resource "kubernetes_namespace" "argocd" {
  depends_on = [helm_release.prometheus_operator]

  metadata {
    name = "sys-argocd"
  }
}

resource "kubectl_manifest" "argocd_zitadel" {
  depends_on = [kubectl_manifest.secret_store]

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "argocd-zitadel"
      namespace = "sys-argocd"
      labels = {
        "app.kubernetes.io/part-of" = "argocd"
      }
    },
    spec = {
      secretStoreRef = {
        kind = "ClusterSecretStore"
        name = "oracle"
      }
      target = {
        name           = "argocd-zitadel"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "client-secret"
          remoteRef = {
            key = "argocd-client-secret"
          }
        },
        {
          secretKey = "client-id"
          remoteRef = {
            key = "argocd-client-id"
          }
        }
      ]
    }
  })
}

resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd, kubectl_manifest.argocd_zitadel]

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
issuer: https://${var.zitadel_host}
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
g, ${var.zitadel_project}:admin, role:admin
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
        targetRevision = "chore/argo"

        helm = {
          values = <<EOF
project: ${var.cluster_name}
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
