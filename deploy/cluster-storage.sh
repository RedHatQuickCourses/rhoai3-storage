#!/bin/bash

# ==============================================================================
# Script Name: create-cluster-storage.sh
# Description: Provisions persistent Cluster Storage (PVC) for an RHOAI Project.
#              Supports both Personal (RWO) and Shared (RWX) modes.
# Usage:       ./create-cluster-storage.sh <project-name> <pvc-name> <size-gb> <mode>
# Example:     ./create-cluster-storage.sh my-ai-project team-data-share 50 rwx
# ==============================================================================

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <project-name> <pvc-name> <size-gb> <mode>"
    echo "  <mode>: 'rwo' (Single User/Fast) or 'rwx' (Shared/Collaborative)"
    exit 1
fi

PROJECT_NAME=$1
PVC_NAME=$2
SIZE_GB=$3
MODE_INPUT=$(echo "$4" | tr '[:upper:]' '[:lower:]')

# --- CONFIGURATION: EDIT THIS TO MATCH YOUR CLUSTER ---
# You can find your classes by running: oc get sc
# Common examples: 'gp3-csi', 'ocs-storagecluster-ceph-rbd', 'nfs-client'

# 1. Class for Single User (Block Storage - Fast)
RWO_STORAGE_CLASS="gp3-csi"

# 2. Class for Shared Team (File Storage - NFS/CephFS)
RWX_STORAGE_CLASS="ocs-storagecluster-cephfs"
# ------------------------------------------------------

# Logic to select the right Access Mode and Class
if [ "$MODE_INPUT" == "rwx" ]; then
    ACCESS_MODE="ReadWriteMany"
    STORAGE_CLASS=$RWX_STORAGE_CLASS
    echo "🔹 Configuration: Shared Storage (RWX) using class '$STORAGE_CLASS'"
elif [ "$MODE_INPUT" == "rwo" ]; then
    ACCESS_MODE="ReadWriteOnce"
    STORAGE_CLASS=$RWO_STORAGE_CLASS
    echo "🔹 Configuration: Personal Storage (RWO) using class '$STORAGE_CLASS'"
else
    echo "❌ Error: Mode must be 'rwo' or 'rwx'."
    exit 1
fi

echo "Creating ${SIZE_GB}Gi Storage in '$PROJECT_NAME'..."

cat <<EOF | oc apply -n "$PROJECT_NAME" -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PVC_NAME
  labels:
    # Optional: Tags to help admins organize storage
    opendatahub.io/storage-type: "general-purpose"
    created-by: "platform-automation"
spec:
  accessModes:
    - $ACCESS_MODE
  resources:
    requests:
      storage: ${SIZE_GB}Gi
  storageClassName: $STORAGE_CLASS
  volumeMode: Filesystem
EOF

if [ $? -eq 0 ]; then
    echo "✅ Success! PVC '$PVC_NAME' created."
    echo "   To attach this to a workbench:"
    echo "   1. Go to RHOAI Dashboard -> Workbenches"
    echo "   2. 'Add existing storage' -> Select '$PVC_NAME'"
else
    echo "❌ Error creating storage."
fi