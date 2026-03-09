#!/bin/bash

# ==============================================================================
# Script Name: cluster-storage.sh
# Description: Provisions a Shared Pipeline Workspace (RWX) using CephFS.
# Usage:       ./cluster-storage.sh <project-name> <pvc-name> <size-gb>
# ==============================================================================

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <project-name> <pvc-name> <size-gb>"
    exit 1
fi

PROJECT_NAME=$1
PVC_NAME=$2
SIZE_GB=$3

# --- USING YOUR NATIVE FILE STORAGE ---
STORAGE_CLASS="ocs-external-storagecluster-cephfs"

echo "🔹 Configuration: Shared Workspace (RWX) using class '$STORAGE_CLASS'"
echo "Creating ${SIZE_GB}Gi Storage in '$PROJECT_NAME'..."

cat <<EOF | oc apply -n "$PROJECT_NAME" -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PVC_NAME
  labels:
    opendatahub.io/dashboard: "true"
    opendatahub.io/storage-type: "general-purpose"
    created-by: "platform-automation"
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: ${SIZE_GB}Gi
  storageClassName: $STORAGE_CLASS
  volumeMode: Filesystem
EOF

echo "✔ Persistent Volume Claim created successfully."