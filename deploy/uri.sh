#!/bin/bash

# ==============================================================================
# Script Name: create-uri-connection.sh
# Description: Creates a URI Data Connection for RHOAI 3.x
#              Used for direct HTTP/HTTPS paths to private object storage.
# Usage:       ./create-uri-connection.sh <project-name>
# ==============================================================================

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <project-name>"
    exit 1
fi

PROJECT_NAME=$1
CONNECTION_NAME="private-model-uri"

# --- CONFIGURATION ---
# The direct path to the folder or file
# Format: s3://<bucket>/<path> OR https://<endpoint>/<bucket>/<path>
MODEL_URI="s3://private-models/Qwen3-0.6B/1.0.0/"

# Credentials for the private bucket
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-minio}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-minio123}"
AWS_S3_ENDPOINT="${AWS_S3_ENDPOINT:-minio-service.$PROJECT_NAME.svc.cluster.local:9000}"
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
# ---------------------

echo "Creating URI Data Connection in '$PROJECT_NAME'..."

cat <<EOF | oc apply -n "$PROJECT_NAME" -f -
apiVersion: v1
kind: Secret
metadata:
  name: $CONNECTION_NAME
  labels:
    opendatahub.io/dashboard: "true"
    opendatahub.io/managed: "true"
  annotations:
    # LINK TO TEMPLATE: Uses the 'uri' icon (Globe/Link symbol)
    opendatahub.io/connection-type: "uri"
    
    # DRIVER PROTOCOL: Treats this as a direct URI resource
    opendatahub.io/connection-type-protocol: "uri"

    openshift.io/display-name: "Custom URI Link"
    openshift.io/description: "Direct URI link to private model artifacts."
type: Opaque
stringData:
  # The Primary Field: Where is it?
  URI: "$MODEL_URI"
  
  # Optional/Contextual Fields:
  # If the URI is an 's3://' scheme, many RHOAI runtimes (like KServe)
  # still need these standard AWS variables to authenticate the request.
  AWS_ACCESS_KEY_ID: "$AWS_ACCESS_KEY_ID"
  AWS_SECRET_ACCESS_KEY: "$AWS_SECRET_ACCESS_KEY"
  AWS_S3_ENDPOINT: "$AWS_S3_ENDPOINT"
  AWS_DEFAULT_REGION: "$AWS_DEFAULT_REGION"
EOF

if [ $? -eq 0 ]; then
    echo "✅ Success! URI Connection created."
    echo "   Target: $MODEL_URI"
    echo "   Type:   URI (Private)"
else
    echo "❌ Error creating connection."
fi