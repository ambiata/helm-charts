{{/*
Expand the name of the chart.
*/}}
{{- define "minio-manager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "minio-manager.fullname" -}}
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
{{- define "minio-manager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "minio-manager.labels" -}}
helm.sh/chart: {{ include "minio-manager.chart" . }}
{{ include "minio-manager.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "minio-manager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "minio-manager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create envs template for minio connection
*/}}
{{- define "minio-manager.minioAdminCredentialEnvs" }}
- name: MINIO_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      key: {{ .secretKeys.accessKey }}
      name: {{ required "The secret for minio credentials minioAdminCredentials.secretName is required" .secretName }}
- name: MINIO_SECRET_KEY
  valueFrom:
    secretKeyRef:
      key: {{ .secretKeys.secretKey }}
      name: {{ .secretName }}
- name: MINIO_ENDPOINT
  valueFrom:
    secretKeyRef:
      key: {{ .secretKeys.endpointUrl }}
      name: {{ .secretName }}
- name: MINIO_USE_SSL
  valueFrom:
    secretKeyRef:
      key: {{ .secretKeys.useSsl }}
      name: {{ .secretName }}
{{- end }}

{{/*
From a list of bucket names, create the aws resources list in a json format.
Add access to the buckets 'probe-bucket-sign-*' which are required for the minio cli 'mc' to be configured. It read
some data from these buckets to validate that the connection is working.
*/}}
{{- define "bucketListToResourceJsonList" }}
{{- $rs := dict "resources" (list) -}}
{{- if eq (len .) 0 }}
{{- fail "'policies[i].buckets' should not be empty to create a policy, otherwise use 'readonly' or 'readwrite' default policies." }}
{{- end }}
{{/*
go does not have a map method on list, so need to create a new list from the received one.
Solution inspired from https://stackoverflow.com/questions/47668793/helm-generate-comma-separated-list/47669673#47669673
Create a dictionary, with a single key containing a list. Append the values to the list and set in the dictionary the
key to the new appended list.
*/}}
{{- range . -}}
{{- $noop := printf "arn:aws:s3:::%s/*" . | append $rs.resources | set $rs "resources" -}}
{{- $noop := printf "arn:aws:s3:::%s" . | append $rs.resources | set $rs "resources" -}}
{{- end -}}
{{- $noop := printf "arn:aws:s3:::probe-bucket-sign-*" | append $rs.resources | set $rs "resources" -}}
{{- toJson $rs.resources -}}
{{- end }}

{{/*
Create the policy file for minio to give access to a selected list of buckets.
Only two types of policies can be created: readonly or readwrite on these selected buckets.
*/}}
{{- define "minio-manager.createPolicyFileBash" }}
cat << EOF > policy-{{ .name }}.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": [
        {{- if .readOnly }}
        "s3:GetBucketLocation",
        "s3:GetObject"
        {{- else }}
        "s3:*"
        {{- end }}
      ],
      "Resource": {{- required "'policies[i].buckets' is required to create a policy, otherwise use 'readonly' or 'readwrite' default policies." .buckets | include "bucketListToResourceJsonList" }}
    }
  ]
}
EOF
{{- end }}

{{/*
Create USER environment variable
*/}}
{{- define "user-env-var" }}
- name: USER{{ .index }}
  valueFrom:
    secretKeyRef:
      name: {{ .user.userCredentialsSecret }}
      key: {{ .user.usernameSecretKey | default "username" }}
{{- end }}
