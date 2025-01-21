resource "kubernetes_namespace" "monitoring" {
  depends_on = [helm_release.linkerd]

  metadata {
    name = "sys-monitoring"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }

    annotations = {
      "linkerd.io/inject"                        = "enabled"
    }
  }
}

resource "kubectl_manifest" "grafana_zitadel" {
  depends_on = [kubectl_manifest.secret_store]

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "grafana-zitadel"
      namespace = "sys-monitoring"
    },
    spec = {
      secretStoreRef = {
        kind = "ClusterSecretStore"
        name = "oracle"
      }
      target = {
        name           = "grafana-zitadel"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "client-secret"
          remoteRef = {
            key = "grafana-client-secret"
          }
        },
        {
          secretKey = "client-id"
          remoteRef = {
            key = "grafana-client-id"
          }
        }
      ]
    }
  })
}

resource "helm_release" "prometheus_operator" {
  depends_on = [kubernetes_namespace.monitoring, helm_release.ingress, kubectl_manifest.grafana_zitadel]

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "66.3.0"

  namespace = "sys-monitoring"
  name      = "prometheus"

  values = [yamlencode({
    defaultRules = {
      rules = {
        kubeControllerManager = false
        kubeSchedulerAlerting = false
      }
    }

    alertmanager = {
      config = {
        route = {
          receiver = "discord"
        }
        receivers = [
          {
            name = "discord"
            discord_configs = [
              {
                webhook_url = var.discord_webhook
              }
            ]
          },
          {
            name = "null"
          }
        ]
      }
    }

    grafana = {
      "grafana.ini" = {
        users = {
          allow_sign_up = false
        }
        server = {
          domain   = "grafana.internal.${var.cluster_domain}"
          root_url = "https://grafana.internal.${var.cluster_domain}"
        }
        "auth.generic_oauth" = {
          enabled           = true
          allow_sign_up     = true
          auto_login        = false
          use_pkce          = false
          use_refresh_token = true
          name              = "Zitadel"

          client_id     = "$__file{/etc/secrets/zitadel/client-id}"
          client_secret = "$__file{/etc/secrets/zitadel/client-secret}"
          scopes        = "openid profile email offline_access roles"
          auth_url      = "https://${var.zitadel_host}/oauth/v2/authorize"
          token_url     = "https://${var.zitadel_host}/oauth/v2/token"
          api_url       = "https://${var.zitadel_host}/oidc/v1/userinfo"

          email_attribute_name = "email"
          login_attribute_path = "username"
          name_attribute_path  = "fullname"

          role_attribute_path = "contains(keys(\"urn:zitadel:iam:org:project:roles\"), 'admin') && 'Admin' || contains(keys(\"urn:zitadel:iam:org:project:roles\"), 'grafana-editor') && 'Editor' || contains(keys(\"urn:zitadel:iam:org:project:roles\"), 'grafana-viewer') && 'Viewer' || 'None'"
        }
      }

      dashboardProviders = {
        "dashboardproviders.yaml" = {
          apiVersion = 1
          providers = [
            {
              name  = "default"
              orgId = 1
              folder : ""
              type            = "file"
              disableDeletion = false
              editable        = true
              options = {
                path = "/var/lib/grafana/dashboards/default"
              }
          }]
        }
      }

      dashboards = {
        default = {
          ingress-nginx = {
            gnetId     = 16677
            datasource = "Prometheus"
          }

          external-dns = {
            gnetId     = 15038
            datasource = "Prometheus"
          }

          external-secrets = {
            gnetId = 21640
            datasource = [
              {
                name  = "DS_PROMETHEUS"
                value = "Prometheus"
              }
            ]
          }

          longhorn = {
            gnetId = 16888
            datasource = [
              {
                name  = "DS_PROMETHEUS"
                value = "Prometheus"
              }
            ]
          }

          cert-manager = {
            gnetId = 11001
            datasource = [
              {
                name  = "DS_PROMETHEUS"
                value = "Prometheus"
              }
            ]
          }
        }
      }

      ingress = {
        enabled          = true
        hosts            = ["grafana.internal.${var.cluster_domain}"]
        ingressClassName = "internal"
      }

      persistence = {
        enabled          = true
        storageClassName = "longhorn"
        accessModes      = ["ReadWriteOnce"]
        size             = "5Gi"
        finalizers       = ["kubernetes.io/pvc-protection"]
      }

      extraSecretMounts = [
        {
          name       = "grafana-zitadel"
          secretName = "grafana-zitadel"
          readOnly   = true
          optional   = false
          mountPath  = "/etc/secrets/zitadel"
        }
      ]
    }

    prometheus = {
      prometheusSpec = {
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
        probeSelectorNilUsesHelmValues          = false

        retentionSize = "9GB"

        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "longhorn"
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = "10Gi"
                }
              }
            }
          }
        }
      }
    }
  })]
}
