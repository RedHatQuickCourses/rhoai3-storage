#!/bin/bash

# ==============================================================================
# Script Name: cluster-storage.sh
# Description: Provisions persistent Block Storage (RWO) for an AI Project.
#              (Tailored for cloud environments like AWS EBS / gp3-csi)
# Usage:       ./cluster-storage.sh <project-name> <pvc-name> <size-gb>
# Example:     ./cluster-storage.sh ai-supply-chain golden-dataset 100
# ==============================================================================

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <project-name> <pvc-name> <size-gb>"
    exit 1
fi

PROJECT_NAME=$1
PVC_NAME=$2
SIZE_GB=$3

# --- CONFIGURATION: EDIT THIS TO MATCH YOUR CLUSTER ---
# Find your available RWO classes by running: oc get sc
STORAGE_CLASS="gp3-csi" # Defaulting to AWS block storage
# ------------------------------------------------------

echo "🔹 Configuration: Block Storage (RWO) using class '$STORAGE_CLASS'"
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
    - ReadWriteOnce
  resources:
    requests:
      storage: ${SIZE_GB}Gi
  storageClassName: $STORAGE_CLASS
  volumeMode: Filesystem
EOF

echo "✔ Persistent Volume Claim created successfully."
echo "⏳ Note: Block storage may remain in 'WaitForFirstConsumer' state until mounted by a Pod."