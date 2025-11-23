resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "sys-argocd"
  }
}

resource "kubernetes_secret" "argocd" {
  metadata {
    name      = "argocd-credentials"
    namespace = kubernetes_namespace.argocd.metadata[0].name

    labels = {
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    client-id      = var.application_credentials.argocd.client_id
    client-secret  = var.application_credentials.argocd.client_secret
    redis-password = var.redis_password
  }
}

resource "age_secret_key" "argocd" {}

resource "kubernetes_secret" "argocd_age" {
  metadata {
    name      = "argocd-age"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  data = {
    "key.txt" = age_secret_key.argocd.secret_key
  }
}

resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd, kubernetes_secret.argocd]

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.6.4"

  namespace = "sys-argocd"
  name      = "argocd"

  values = [yamlencode({
    global = {
      domain = "argocd.internal.${var.cluster_domain}"
    }

    redis = {
      enabled = false
    }

    externalRedis = {
      host           = "${var.redis_host}"
      existingSecret = kubernetes_secret.argocd.metadata[0].name
    }

    redisSecretInit = {
      enabled = false
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
        "server.insecure" = true
      }

      cm = {
        "kustomize.buildOptions" = "--enable-alpha-plugins --enable-exec"
        "oidc.config"            = <<EOF
name: Entra
issuer: ${var.oidc_url}
clientID: $argocd-credentials:client-id 
clientSecret: $argocd-credentials:client-secret
requestedScopes:
  - openid
  - profile
  - email
EOF
        url                      = "https://argocd.internal.${var.cluster_domain}"
      }

      rbac = {
        "policy.csv" = <<EOF
g, ${var.groups.argocd}, role:admin
EOF
      }
    }

    applicationSet = {
      extraVolumes      = [var.ca_volume]
      extraVolumeMounts = [var.ca_volume_mount]
    }

    server = {
      volumes      = [var.ca_volume]
      volumeMounts = [var.ca_volume_mount]

      extraArgs = [
        "--redisdb=4",
        "--redis-use-tls"
      ]

      service = {
        servicePortHttpsAppProtocol = "HTTPS"
      }
    }

    controller = {
      volumes      = [var.ca_volume]
      volumeMounts = [var.ca_volume_mount]

      extraArgs = [
        "--redisdb=4",
        "--redis-use-tls"
      ]
    }

    repoServer = {
      volumes = [
        var.ca_volume,
        {
          name     = "sops"
          emptyDir = {}
        },
        {
          name = "age"
          secret = {
            secretName = "argocd-age"
          }
        }
      ]

      volumeMounts = [
        var.ca_volume_mount,
        {
          name      = "age"
          readOnly  = true
          mountPath = "/age"
        },
        {
          name      = "sops"
          mountPath = "/usr/local/bin/kustomize"
          subPath   = "kustomize"
        },
        {
          name      = "sops"
          mountPath = "/usr/local/bin/ksops"
          subPath   = "ksops"
        }
      ]

      extraArgs = [
        "--redisdb=4",
        "--redis-use-tls"
      ]

      env = [
        {
          name  = "SOPS_AGE_KEY_FILE"
          value = "/age/key.txt"
        }
      ]

      initContainers = [
        {
          name    = "install-ksops"
          image   = "viaductoss/ksops:v4.3.0"
          command = ["/bin/sh", "-c"]
          args = [<<EOF
            echo "Installing KSOPS...";
            mv ksops /sops/;
            mv kustomize /sops/;
            echo "Done.";
EOF
          ]
          volumeMounts = [
            {
              name      = "sops"
              mountPath = "/sops"
            }
          ]
        }
      ]
    }

    dex = {
      enabled = false
    }
  })]
}

resource "kubectl_manifest" "argocd_route" {
  depends_on = [helm_release.argocd]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "argocd"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name        = "private"
          sectionName = "https"
          namespace   = "default"
        }
      ]
      hostnames = ["argocd.internal.${var.cluster_domain}"]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = "argocd-server"
              port = 443
            }
          ]
        }
      ]
    }
  })
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
        path           = "gitops/bootstrap"
        targetRevision = "main"
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
