{{/*
Expand the name of the chart.
*/}}
{{- define "postgres-db-manager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "postgres-db-manager.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "postgres-db-manager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "postgres-db-manager.labels" -}}
helm.sh/chart: {{ include "postgres-db-manager.chart" . }}
{{ include "postgres-db-manager.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "postgres-db-manager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "postgres-db-manager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create envs template for postgresql connection
*/}}
{{- define "postgres-db-manager.postgresqlAdminCredentialEnvs" }}
- name: PGDB
  value: {{ required "The .postgresqlAdminCredentials.initDb is required" .initDb }}
- name: PGHOST
  valueFrom:
    secretKeyRef:
      key: {{ .secretKeys.host }}
      name: {{ required "The secret for postgresql credentials postgresqlAdminCredentials.secretName is required" .secretName }}
- name: PGPASSWORD
  valueFrom:
    secretKeyRef:
      key: {{ .secretKeys.password }}
      name: {{ .secretName }}
- name: PGUSER
  valueFrom:
    secretKeyRef:
      key: {{ .secretKeys.user }}
      name: {{ .secretName }}
- name: PGPORT
  valueFrom:
    secretKeyRef:
      key: {{ .secretKeys.port }}
      name: {{ .secretName }}
{{- end }}

