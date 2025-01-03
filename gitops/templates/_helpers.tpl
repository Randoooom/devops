{{- define "common" }}
project: {{ .Values.project }}
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  syncOptions:
    - CreateNamespace=true
  managedNamespaceMetadata:
    annotations:
      linkerd.io/inject: {{ .linkerd | default "disabled" }}
    {{- if eq .linkerd "enabled" }}
    labels:
      pod-security.kubernetes.io/enforce: privileged
    {{- end }}
{{- end }}
