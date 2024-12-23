resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "sys-external-secrets"
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
      name      = "postgres",
      namespace = "postgres",
      secrets = [
        {
          name = "postgres-admin-password"
          key  = "postgres-admin-password"
        },
        {
          name = "postgres-replication-password"
          key  = "postgres-replication-password"
        },
        {
          name = "postgres-password"
          key  = "postgres-password"
        }
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
