{{- define "common" }}
project: {{ .Values.project }}
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  syncOptions:
    - CreateNamespace=true
    - ServerSideApply=true
{{- end }}
