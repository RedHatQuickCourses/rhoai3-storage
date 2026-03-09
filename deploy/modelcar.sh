#!/bin/bash

# ==============================================================================
# Script Name: create-oci-connection.sh
# Description: Creates a Public OCI Data Connection for RHOAI 3.x
#              Used for "Modelcars" (booting models from container images).
# Usage:       ./create-oci-connection.sh <project-name>
# ==============================================================================


if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <project-name>"
    exit 1
fi

PROJECT_NAME=$1
CONNECTION_NAME="granite-3-8b-modelcar"

# The OCI Image URI (Public)
MODEL_IMAGE="quay.io/redhat-ai-services/modelcar-catalog:granite-3.2-8b-instruct"

echo "Creating OCI Data Connection in '$PROJECT_NAME'..."

cat <<EOF | oc apply -n "$PROJECT_NAME" -f -
apiVersion: v1
kind: Secret
metadata:
  name: $CONNECTION_NAME
  labels:
    opendatahub.io/dashboard: "true"
    opendatahub.io/managed: "true" # <-- ADDED: 3.3 UI Visibility Requirement
  annotations:
    opendatahub.io/connection-type: "oci"
    opendatahub.io/connection-type-protocol: "oci" # <-- ADDED: 3.3 Backend Routing Requirement
    openshift.io/display-name: "Granite 3.2 8B (Modelcar)"
    openshift.io/description: "Public OCI image from Red Hat Modelcar catalog."
type: Opaque
stringData:
  # For OCI connections, we typically just need the full URI.
  URI: "oci://$MODEL_IMAGE"
EOF

if [ $? -eq 0 ]; then
    echo "✅ Success! OCI Connection created."
    echo "   Image: $MODEL_IMAGE"
    echo "   Type:  Modelcar (Public)"
else
    echo "❌ Error creating connection."
fi