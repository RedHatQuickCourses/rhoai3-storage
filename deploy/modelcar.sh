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
    # Visibility Label
    opendatahub.io/dashboard: "true"
    opendatahub.io/managed: "true"
  annotations:
    # LINK TO TEMPLATE: Uses the 'oci' icon and form style
    opendatahub.io/connection-type: "oci"
    
    # DRIVER PROTOCOL: Tells RHOAI this is a container image source
    opendatahub.io/connection-type-protocol: "oci"

    openshift.io/display-name: "Granite 3.2 8B (Modelcar)"
    openshift.io/description: "Public OCI image from Red Hat Modelcar catalog."
type: Opaque
stringData:
  # For OCI connections, we typically just need the full URI.
  # No Username/Password required for public Quay.io images.
  OCI_URI: "$MODEL_IMAGE"
EOF

if [ $? -eq 0 ]; then
    echo "✅ Success! OCI Connection created."
    echo "   Image: $MODEL_IMAGE"
    echo "   Type:  Modelcar (Public)"
else
    echo "❌ Error creating connection."
fi