#!/bin/bash

# =================================================================================
# SCRIPT: setup.sh
# DESCRIPTION: Automates the "Plumbing" phase of the Data Supply Chain Lab.
#              1. Creates the Namespace
#              2. Deploys MinIO (Object Storage) from local file
#              3. Deploys MySQL (Metadata Storage) from local file
#              4. Creates Service Account with storage permissions
#              5. Creates S3 Data Connection for RHOAI
# =================================================================================

set -e # Exit immediately if a command exits with a non-zero status

# =================================================================================
# CONFIGURATION VARIABLES
# =================================================================================
NAMESPACE="rhoai-storage-lab"
SA_NAME="ai-pipeline-sa"

# Credentials (Must match what is inside your yaml files)
MYSQL_DATABASE="sampledb"
MINIO_ACCESS_KEY="minio"
MINIO_SECRET_KEY="minio123"
MINIO_BUCKET="models"

# Manifest Paths (Assumes files are in the same directory as this script)
MINIO_MANIFEST="infrastructure/minio/minio-backend.yaml"
MYSQL_MANIFEST="infrastructure//mysql/*"

echo "🚀 Starting AI Supply Chain Infrastructure Setup..."

# ---------------------------------------------------------------------------------
# 1. Namespace Management
# ---------------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Step 1: Checking Namespace [$NAMESPACE]..."
if oc get project "$NAMESPACE" > /dev/null 2>&1; then
    echo "✔ Namespace $NAMESPACE exists."
else
    echo "➤ Creating namespace $NAMESPACE..."
    oc new-project "$NAMESPACE"
fi

# ---------------------------------------------------------------------------------
# 2. Deploy MinIO (The Vault)
# ---------------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Step 2: Deploying MinIO Object Storage..."

if [ -f "$MINIO_MANIFEST" ]; then
    echo "➤ Applying local $MINIO_MANIFEST..."
    oc apply -f "$MINIO_MANIFEST" -n "$NAMESPACE"
else
    echo "❌ Error: $MINIO_MANIFEST not found in current directory!"
    exit 1
fi

# ---------------------------------------------------------------------------------
# 3. Deploy MySQL (The Brain)
# ---------------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Step 3: Deploying MySQL Database..."

if [ -f "$MYSQL_MANIFEST" ]; then
    echo "➤ Applying local $MYSQL_MANIFEST..."
    oc apply -f "$MYSQL_MANIFEST" -n "$NAMESPACE"
else
    echo "❌ Error: $MYSQL_MANIFEST not found in current directory!"
    exit 1
fi

# ---------------------------------------------------------------------------------
# 4. Service Account & Permissions
# ---------------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Step 4: Configuring Service Account [$SA_NAME]..."

if oc get sa "$SA_NAME" -n "$NAMESPACE" > /dev/null 2>&1; then
    echo "✔ Service Account $SA_NAME already exists."
else
    echo "➤ Creating Service Account..."
    oc create sa "$SA_NAME" -n "$NAMESPACE"
fi

echo "➤ Granting 'edit' role to $SA_NAME..."
oc policy add-role-to-user edit -z "$SA_NAME" -n "$NAMESPACE"

# ---------------------------------------------------------------------------------
# 5. Create Storage Secret (Data Connection)
# ---------------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Step 5: Creating S3 Data Connection..."

echo "➤ Creating 'aws-connection-minio' in $NAMESPACE..."

oc create secret generic aws-connection-minio \
    --from-literal=AWS_ACCESS_KEY_ID="$MINIO_ACCESS_KEY" \
    --from-literal=AWS_SECRET_ACCESS_KEY="$MINIO_SECRET_KEY" \
    --from-literal=AWS_S3_ENDPOINT="http://minio-service.$NAMESPACE.svc.cluster.local:9000" \
    --from-literal=AWS_DEFAULT_REGION="us-east-1" \
    --from-literal=AWS_S3_BUCKET="$MINIO_BUCKET" \
    -n "$NAMESPACE" \
    --dry-run=client -o yaml | \
    oc apply -f -

oc label secret aws-connection-minio \
    "opendatahub.io/dashboard=true" \
    "opendatahub.io/managed=true" \
    -n "$NAMESPACE" \
    --overwrite

echo "✔ Storage Secret Created. It is now visible in the RHOAI Dashboard."

# ---------------------------------------------------------------------------------
# 6. Summary
# ---------------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "✅ Infrastructure Setup Complete!"
echo "🔹 Namespace:      $NAMESPACE"
echo "🔹 Service Acct:   $SA_NAME"
echo "🔹 MinIO Console:  http://minio-service.$NAMESPACE.svc.cluster.local:9000"
echo "🔹 MySQL Host:     mysql.$NAMESPACE.svc.cluster.local"
echo "----------------------------------------------------------------"