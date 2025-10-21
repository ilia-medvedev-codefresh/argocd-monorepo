{{- range $count, $val := until (int .Values.configmaps.count) }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "resource-generator.fullname" $ }}-{{ $count }}
  labels:
    {{- include "resource-generator.labels" $ | nindent 4 }}
data:
  {{- with $.Values.configmaps.data }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
---
{{- end }}
