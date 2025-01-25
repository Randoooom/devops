resource "kubernetes_namespace" "external_secrets" {
  depends_on = [helm_release.linkerd]

  metadata {
    name = "sys-external-secrets"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }

    annotations = {
      "linkerd.io/inject" = "enabled"
    }
  }
}

resource "helm_release" "external_secrets" {
  depends_on = [kubernetes_namespace.external_secrets]

  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.11.0"

  namespace = "sys-external-secrets"
  name      = "external-secrets"

  values = [yamlencode({
    installCRDs = true
    serviceMonitor = {
      enabled = true
    }
  })]
}

resource "kubectl_manifest" "secret_store" {
  depends_on = [helm_release.external_secrets]

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "oracle"
    }
    spec = {
      provider = {
        oracle = {
          vault  = var.vault,
          region = var.region
        }
      }
    }
  })
}

locals {
  mounts = [
    {
      name      = "postgres-credentials",
      namespace = "feedback-fusion",
      secrets = [
        {
          name = "postgres-password"
          key  = "feedback-fusion-postgres-admin-password"
        },
        {
          name = "postgres-replication-password"
          key  = "feedback-fusion-postgres-replication-password"
        },
        {
          name = "password"
          key  = "feedback-fusion-postgres-password"
        }
      ]
    },

    {
      name      = "surrealdb-credentials",
      namespace = "event",
      secrets = [
        {
          name = "password"
          key  = "surrealdb-password"
        },
        {
          name = "username"
          key  = "surrealdb-username"
        },
      ]
    }
  ]
}

resource "kubernetes_namespace" "secret_mount" {
  for_each = { for mount in local.mounts : mount.name => mount }

  metadata {
    name = each.value.namespace
  }
}

resource "kubectl_manifest" "secret_mount" {
  depends_on = [kubernetes_namespace.secret_mount]

  for_each = { for mount in local.mounts : mount.name => mount }

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = each.key
      namespace = each.value.namespace
    },
    spec = {
      secretStoreRef = {
        kind = "ClusterSecretStore"
        name = "oracle"
      }
      target = {
        name           = each.key
        creationPolicy = "Owner"
      }
      data = [for secret in each.value.secrets : {
        secretKey = secret.name
        remoteRef = {
          key = secret.key
        }
      }]
    }
  })
}

data "kubernetes_secret" "postgres_credentials" {
  depends_on = [kubectl_manifest.secret_mount]

  metadata {
    name      = "postgres-credentials"
    namespace = "feedback-fusion"
  }
}

resource "kubernetes_secret" "feedback_fusion_config" {
  metadata {
    name      = "feedback-fusion-config"
    namespace = "feedback-fusion"
  }

  data = {
    "config.yaml" = yamlencode({
      oidc = {
        provider     = "https://${var.zitadel_host}"
        audience     = var.feedback_fusion_client_id
        issuer       = "https://${var.zitadel_host}"
        groups_claim = "groups"
        scopes       = []
        groups = [
          {
            name = "${var.zitadel_project}:feedback-fusion"
            grants = [
              {
                endpoint    = "*"
                permissions = ["*"]
              }
            ]
          }
        ]
      }

      database = {
        postgres = {
          endpoint = "feedback-fusion-postgres-postgresql:5432"
          username = "feedback-fusion"
          password = data.kubernetes_secret.postgres_credentials.data.password
          database = "feedback-fusion"
        }
      }

      otlp = {
        endpoint = "http://tempo.sys-monitoring.svc.cluster.local:4317"
      }
    })
  }
}

resource "kubernetes_secret" "feedback_fusion_dasboard_config" {
  depends_on = [kubectl_manifest.secret_mount]

  metadata {
    name      = "feedback-fusion-dashboard-config"
    namespace = "feedback-fusion"
  }

  data = {
    NUXT_PUBLIC_FEEDBACK_FUSION_ENDPOINT           = "https://feedback-fusion.${var.cluster_domain}"
    NUXT_OIDC_PROVIDERS_OIDC_AUTHORIZATION_URL     = "https://${var.zitadel_host}/oauth/v2/authorize"
    NUXT_OIDC_PROVIDERS_OIDC_TOKEN_URL             = "https://${var.zitadel_host}/oauth/v2/token"
    NUXT_OIDC_PROVIDERS_OIDC_CLIENT_ID             = "${var.feedback_fusion_client_id}"
    NUXT_OIDC_PROVIDERS_OIDC_CLIENT_SECRET         = "${var.feedback_fusion_client_secret}"
    NUXT_OIDC_PROVIDERS_OIDC_REDIRECT_URI          = "https://feedback-fusion.${var.public_domain}/auth/oidc/callback"
    NUXT_OIDC_PROVIDERS_OIDC_OPEN_ID_CONFIGURATION = "https://${var.zitadel_host}/.well-known/openid-configuration"
  }
}
