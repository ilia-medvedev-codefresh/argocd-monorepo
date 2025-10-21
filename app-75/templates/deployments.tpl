{{- range $count, $val := (until (int $.Values.deployments.count)) }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "resource-generator.fullname" $ }}-{{ $count }}
  labels:
    {{- include "resource-generator.labels" $ | nindent 4 }}
spec:
  replicas: {{ $.Values.deployments.replicaCount }}
  selector:
    matchLabels:
      {{- include "resource-generator.selectorLabels" $ | nindent 6 }}
      generator-index: {{ $count | quote }}
  template:
    metadata:
      {{- with $.Values.deployments.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "resource-generator.labels" $ | nindent 8 }}
        generator-index: {{ $count | quote }}
        {{- with $.Values.deployments.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      {{- with $.Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ ternary (printf "%s-%s" (include "resource-generator.serviceAccountName" $) $count) "default" $.Values.deployments.serviceAccount.create }}
      securityContext:
        {{- toYaml $.Values.deployments.podSecurityContext | nindent 8 }}
      containers:
        {{ $.Values.deployments.containers | toYaml | nindent 8 }}
      {{- with $.Values.deployments.volumes }}
      volumes:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $.Values.deployments.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $.Values.deployments.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $.Values.deployments.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
---
{{- end }}
