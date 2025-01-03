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
{{- end }}
