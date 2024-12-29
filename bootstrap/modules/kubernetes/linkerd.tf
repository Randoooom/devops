resource "kubernetes_namespace" "linkerd" {
  metadata {
    name = "sys-linkerd"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "linkerd_crds" {
  depends_on = [kubernetes_namespace.linkerd]

  repository = "https://helm.linkerd.io/edge"
  chart      = "linkerd-crds"

  name      = "linkerd-crds"
  namespace = "sys-linkerd"
}

resource "tls_private_key" "ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem       = tls_private_key.ca.private_key_pem
  is_ca_certificate     = true
  set_subject_key_id    = true
  validity_period_hours = 87600
  allowed_uses = [
    "cert_signing",
    "crl_signing"
  ]
  subject {
    common_name = "root.linkerd.cluster.local"
  }
}

resource "tls_private_key" "issuer" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "issuer" {
  private_key_pem = tls_private_key.issuer.private_key_pem
  subject {
    common_name = "identity.linkerd.cluster.local"
  }
}

resource "tls_locally_signed_cert" "issuer" {
  cert_request_pem      = tls_cert_request.issuer.cert_request_pem
  ca_private_key_pem    = tls_private_key.ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca.cert_pem
  is_ca_certificate     = true
  set_subject_key_id    = true
  validity_period_hours = 8760
  allowed_uses = [
    "cert_signing",
    "crl_signing"
  ]
}

resource "helm_release" "linkerd" {
  depends_on = [helm_release.linkerd_crds]

  repository = "https://helm.linkerd.io/edge"
  chart      = "linkerd-control-plane"
  version    = "2024.11.8"

  name      = "linkerd"
  namespace = "sys-linkerd"

  values = [yamlencode({
    podMonitor = {
      enabled = true
    }

    controller = {
      podDistributionBudget = {
        maxUnavailable = 1
      }
    }

    deploymentStrategy = {
      rollingUpdate = {
        maxUnavailable = 1
        maxSurge       = "25%"
      }
    }

    enablePodAffinity  = true
    controllerReplicas = 1
    highAvailability   = false

    identityTrustAnchorsPEM = tls_locally_signed_cert.issuer.ca_cert_pem
    identity = {
      issuer = {
        tls = {
          crtPEM = tls_locally_signed_cert.issuer.cert_pem
          keyPEM = tls_private_key.issuer.private_key_pem
        }
      }
    }
  })]
}
