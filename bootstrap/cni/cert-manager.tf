resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "sys-cert-manager"
  }
}

resource "kubernetes_secret" "cert_manager" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = kubernetes_namespace.cert_manager.metadata[0].name
  }

  data = {
    token = var.cloudflare_api_token
  }
}

resource "helm_release" "cert_manager" {
  depends_on = [kubernetes_namespace.cert_manager]

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.18.2"

  namespace = kubernetes_namespace.cert_manager.metadata[0].name
  name      = "cert-manager"

  values = [yamlencode({
    crds = {
      enabled = true
    }
    prometheus = {
      enabled = true
      servicemonitor = {
        enabled = true
      }
    }
    config = {
      enableGatewayAPI = true
    }
  })]
}

resource "kubectl_manifest" "letsencrypt" {
  depends_on = [helm_release.cert_manager]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt"
    }
    spec = {
      acme = {
        email  = var.acme_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "acme-issuer-account-key"
        }
        solvers = [
          {
            dns01 = {
              cloudflare = {
                apiTokenSecretRef = {
                  name = "cloudflare-api-token"
                  key  = "token"
                }
              }
            }
          }
        ]
      }
    }
  })
}

resource "kubectl_manifest" "cluster_authority_root" {
  depends_on = [helm_release.cert_manager]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "cluster-authority-root"
    }
    spec = {
      selfSigned = {}
    }
  })
}

resource "kubectl_manifest" "cluster_authority_certificate" {
  depends_on = [kubectl_manifest.cluster_authority_root]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "cluster-authority"
      namespace = kubernetes_namespace.cert_manager.metadata[0].name
    }
    spec = {
      duration   = "87600h"
      isCA       = true
      commonName = "cluster-authority"
      secretName = "cluster-authority-ca"
      privateKey = {
        algorithm = "ECDSA"
        size      = 384
      }
      issuerRef = {
        name  = "cluster-authority-root"
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }
    }
  })
}

resource "kubectl_manifest" "cluster_authority" {
  depends_on = [kubectl_manifest.cluster_authority_certificate]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "cluster-authority"
    }
    spec = {
      ca = {
        secretName = "cluster-authority-ca"
      }
    }
  })
}

resource "helm_release" "trust_manager" {
  depends_on = [kubernetes_namespace.cert_manager]

  repository = "https://charts.jetstack.io"
  chart      = "trust-manager"

  namespace = kubernetes_namespace.cert_manager.metadata[0].name
  name      = "trust-manager"

  values = [yamlencode({
    app = {
      trust = {
        namespace = kubernetes_namespace.cert_manager.metadata[0].name
      }
    }
  })]
}

resource "kubectl_manifest" "trust_bundle" {
  depends_on = [kubectl_manifest.cluster_authority, helm_release.trust_manager]

  yaml_body = yamlencode({
    apiVersion = "trust.cert-manager.io/v1alpha1"
    kind       = "Bundle"
    metadata = {
      name = "cluster-authority"
    }
    spec = {
      sources = [
        {
          secret = {
            name = "cluster-authority-ca"
            key  = "ca.crt"
          }

        },
        {
          useDefaultCAs = true
        }
      ]

      target = {
        configMap = {
          key = "root-certs.pem"
        }
      }
    }
  })
}
