#!/bin/bash

# ==============================================================================
# Script Name: uri.sh
# Description: Creates a Direct URI Data Connection for OpenShift AI 3.3
#              Used for precise links to files (e.g., Hugging Face, HTTP servers).
# Usage:       ./uri.sh <project-name>
# ==============================================================================

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <project-name>"
    exit 1
fi

PROJECT_NAME=$1
CONNECTION_NAME="custom-uri-link"

# Example: A direct link to a public model file
MODEL_URI="https://huggingface.co/redhat/granite-7b-instruct/resolve/main/model.safetensors"

echo "Creating URI Data Connection in '$PROJECT_NAME'..."

cat <<EOF | oc apply -n "$PROJECT_NAME" -f -
apiVersion: v1
kind: Secret
metadata:
  name: $CONNECTION_NAME
  labels:
    opendatahub.io/dashboard: "true"
    opendatahub.io/managed: "true" # <-- ADDED: 3.3 UI Visibility Requirement
  annotations:
    opendatahub.io/connection-type: "uri"
    opendatahub.io/connection-type-protocol: "uri" # <-- ADDED: 3.3 Backend Routing Requirement
    openshift.io/display-name: "Custom URI Link"
    openshift.io/description: "Direct link to a specific external model file."
type: Opaque
stringData:
  # The Connections API expects the key 'URI' for this protocol
  URI: "$MODEL_URI"
EOF

echo "✔ URI Connection created successfully."