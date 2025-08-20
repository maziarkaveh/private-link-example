{{/*
Expand the name of the chart.
*/}}
{{- define "postgres-k8s-nlb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "postgres-k8s-nlb.fullname" -}}
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
{{- define "postgres-k8s-nlb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "postgres-k8s-nlb.labels" -}}
helm.sh/chart: {{ include "postgres-k8s-nlb.chart" . }}
{{ include "postgres-k8s-nlb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
omnistrate-instance: {{ .Release.Namespace }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "postgres-k8s-nlb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "postgres-k8s-nlb.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
