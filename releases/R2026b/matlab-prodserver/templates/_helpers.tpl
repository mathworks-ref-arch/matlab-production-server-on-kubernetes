# Chart validation checks:

{{- define "checkConditionReplicaCount" -}}
{{- if and (gt (int .Values.deploymentSettings.replicaCount) 1) .Values.matlabProductionServerSettings.autoDeploy.archivesApi.createPVC }}
{{- if ne .Values.matlabProductionServerSettings.autoDeploy.archivesApi.accessMode "ReadWriteMany" }}
{{- fail "Configuring multiple replicas requires PVC with ReadWriteMany Access-Mode." }}
{{- end }}
{{- end }}
{{- end }}

{{- define "checkConditionVolumeType" -}}
{{- if .Values.matlabProductionServerSettings.autoDeploy.archivesApi.enabled }}
{{- $volumeType := .Values.matlabProductionServerSettings.autoDeploy.volumeType }}
{{- if and (ne $volumeType "pvc") (ne $volumeType "empty") }}
{{- fail "Configuring archives API is only supported with pvc or empty volume types." }}
{{- end }}
{{- end }}
{{- end }}
