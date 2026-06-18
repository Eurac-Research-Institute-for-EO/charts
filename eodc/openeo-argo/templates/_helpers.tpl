{{/*
Expand the name of the chart.
*/}}
{{- define "openeo-argo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "openeo-argo.fullname" -}}
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
{{- define "openeo-argo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openeo-argo.labels" -}}
helm.sh/chart: {{ include "openeo-argo.chart" . }}
{{ include "openeo-argo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openeo-argo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openeo-argo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "openeo-argo.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "openeo-argo.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Common name prefix for resources this chart owns (secrets, RBAC, cronjobs, ...).
Defaults to the release name so multiple instances (e.g. stable + dev) never
collide and every internal reference resolves regardless of the namespace or
overlay. Override with .Values.namePrefix if you need an explicit value.
*/}}
{{- define "openeo-argo.prefix" -}}
{{- default .Release.Name .Values.namePrefix | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Resolve the fullname of a bundled subchart the same way the subchart itself does
(Bitnami/Argo "common.names.fullname"). Call with a dict:
  (dict "top" . "name" "<subchart>" "override" .Values.<subchart>.fullnameOverride)
*/}}
{{- define "openeo-argo.subchartFullname" -}}
{{- $top := .top -}}
{{- $name := .name -}}
{{- $override := .override -}}
{{- if $override -}}
{{- $override | trunc 63 | trimSuffix "-" -}}
{{- else if contains $name $top.Release.Name -}}
{{- $top.Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" $top.Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{/*
Fullnames of the bundled subcharts, used to build their in-cluster DNS / secret names.
*/}}
{{- define "openeo-argo.postgresql.fullname" -}}
{{- include "openeo-argo.subchartFullname" (dict "top" . "name" "postgresql" "override" .Values.postgresql.fullnameOverride) -}}
{{- end }}

{{- define "openeo-argo.redis.fullname" -}}
{{- include "openeo-argo.subchartFullname" (dict "top" . "name" "redis" "override" (index .Values "redis" "fullnameOverride")) -}}
{{- end }}

{{- define "openeo-argo.argoWorkflows.fullname" -}}
{{- include "openeo-argo.subchartFullname" (dict "top" . "name" "argo-workflows" "override" (index .Values "argo-workflows" "fullnameOverride")) -}}
{{- end }}

{{- define "openeo-argo.daskGateway.fullname" -}}
{{- include "openeo-argo.subchartFullname" (dict "top" . "name" "dask-gateway" "override" (index .Values "dask-gateway" "fullnameOverride")) -}}
{{- end }}

{{/*
Name of the ServiceAccount whose token grants access to the Argo Workflows API,
and of the Secret holding that token (created by the post-install hook).
*/}}
{{- define "openeo-argo.argoAccessSAName" -}}
{{- printf "%s-argo-access-sa" (include "openeo-argo.prefix" .) -}}
{{- end }}

{{- define "openeo-argo.argoTokenSecretName" -}}
{{- printf "%s.service-account-token" (include "openeo-argo.argoAccessSAName" .) -}}
{{- end }}

{{/*
Name of the ServiceAccount used by the secret-fixer post-install hook.
*/}}
{{- define "openeo-argo.secretAccessSAName" -}}
{{- printf "%s-secret-access-sa" (include "openeo-argo.prefix" .) -}}
{{- end }}

{{/*
Name of the workspace PersistentVolumeClaim shared with the dask-gateway workers.
Defaults to a static name (PVCs are namespace-isolated, and the dask-gateway
subchart references this claim from non-templated values). Override with
.Values.persistence.claimName, keeping the dask-gateway worker claimName in sync.
*/}}
{{- define "openeo-argo.workspaceClaimName" -}}
{{- default "openeo-workspace" .Values.persistence.claimName -}}
{{- end }}

{{/*
Name of the externally-provided S3 credentials Secret. Defaults to a static name
(namespace-isolated); override with .Values.s3.secretName.
*/}}
{{- define "openeo-argo.s3SecretName" -}}
{{- default "openeo-s3-credentials" .Values.s3.secretName -}}
{{- end }}
