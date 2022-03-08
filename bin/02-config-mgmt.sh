

cat <<EOT >> config-management.yaml
apiVersion: configmanagement.gke.io/v1
kind: ConfigManagement
metadata:
  name: config-management
spec:
  enableMultiRepo: true
  enableLegacyFields: true
  policyController:
    enabled: true
  clusterName: krmapihost-root-cluster
  git:
    policyDir: sync
    secretType: gcpserviceaccount
    gcpServiceAccountEmail: config-sync-sa@PROJECT_ID.iam.gserviceaccount.com
    syncBranch: REPO_BRANCH
    syncRepo: https://source.developers.google.com/p/PROJECT_ID/r/REPO_NAME
  sourceFormat: unstructured
EOT