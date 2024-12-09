{{- define "common" }}
project: {{ .Values.project }}
syncPolicy:
  automated:
    prune: true
    selfHeal: true
{{- end }}
