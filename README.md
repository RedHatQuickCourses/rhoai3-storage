# Red Hat OpenShift AI (RHOAI) Data Connectivity and Storage

**From Credential Sprawl to Governed Connectivity**

> **The Problem:** Keys hardcoded in notebooks, data copied bucket-to-bucket, and siloed storage that blocks collaboration.  
> **The Solution:** Data Connections (credentials in Kubernetes Secrets) and Cluster Storage (PVCs) so the same pipeline runs everywhere and Pipeline Workspaces reduce latency and egress.

This repository contains a complete **course-in-a-box** that teaches platform engineers how to design and operate **data connectivity and storage** in Red Hat OpenShift AI (RHOAI) 3: architecture, well-lit paths (Explorer, Collaborator, Engineer), taxonomy, lab setup, and troubleshooting.

---

## Prerequisites

* **Cluster:** Red Hat OpenShift AI 3 installed and accessible (~1 TB storage recommended for labs)
* **Access:** Permissions to create Secrets, PVCs, and to configure or use StorageClasses (or `cluster-admin`)
* **CLI:** `oc` installed and authenticated (`oc login`)
* **Optional:** GPU operators installed if you will deploy model serving

---

## Quick Start: Connect Your Environment

Follow these steps to get Data Connections and cluster storage working so you can attach credentials to workbenches and deployments without hardcoding keys.

### Step 1: Verify Storage Classes

Ensure the cluster has a default Storage Class (required for PVCs). If you need shared datasets, ensure an RWX-capable class exists.

```bash
oc get storageclass
```

At least one storage class should be marked as default (`storageclass.kubernetes.io/is-default-class=true`).

### Step 2: Create a Data Connection (RHOAI 3 Protocol)

Create a Secret with your S3 (or object store) credentials in the target Data Science Project, then annotate it so RHOAI treats it as a Data Connection.

```bash
export PROJECT=my-data-science-project

oc create secret generic aws-connection-s3 \
  -n $PROJECT \
  --from-literal=AWS_ACCESS_KEY_ID='<access-key>' \
  --from-literal=AWS_SECRET_ACCESS_KEY='<secret-key>' \
  --from-literal=AWS_S3_BUCKET='<bucket-name>' \
  --from-literal=AWS_S3_ENDPOINT='<endpoint-url>' \
  --type=Opaque

oc annotate secret aws-connection-s3 -n $PROJECT \
  opendatahub.io/connection-type-protocol=s3
```

Use the annotation key required by your RHOAI 3.x release (see product documentation). Avoid deprecated connection formats.

### Step 3: Attach the Connection and Deploy a Model

1. In the **OpenShift AI Dashboard**, go to **Model Catalog** or **Deploy model**.
2. Select a **Serving Runtime** and a model that uses object storage.
3. **Attach the Data Connection** you created so the runtime injects S3 credentials into the model server pod.
4. Deploy. The pod should load the model using injected environment variables.

**Verify:**

```bash
oc get pods -n $PROJECT
oc get inferenceservice -n $PROJECT
```

### Step 4: Optional—Test a PVC (RWO)

Confirm dynamic provisioning works with a small PVC:

```bash
oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: $PROJECT
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF

oc get pvc test-pvc -n $PROJECT
```

Status should become `Bound`. If it stays `Pending`, check StorageClass and provisioner.

---

## Repository Structure

```
/
├── modules/                     # Antora course source (AsciiDoc)
│   ├── ROOT/pages/              # Home (includes chapter1)
│   └── chapter1/pages/          # Introduction, Architecture, Well-Lit Paths,
│                               # Taxonomy, Lab Setup, Troubleshooting
├── antora.yml
├── antora-playbook.yml
└── README.md
```

---

## View the Full Course (Antora)

Build and view the full course with architecture details, well-lit paths, and troubleshooting:

**Docker:**

```bash
docker run -u $(id -u) -v $PWD:/antora:Z --rm -t antora/antora antora-playbook.yml
# open build/site/index.html
```

**NPM:**

```bash
npm install
npx antora antora-playbook.yml
# open build/site/index.html
```

---

## Troubleshooting

### Data Connection not injecting credentials

* Verify the Secret exists and is named as expected: `oc get secret -n <project>`
* Check the pod has the Secret as env or volume: `oc get pod <pod> -n <project> -o yaml`
* Ensure the Secret has the RHOAI 3 connection-type annotation: `oc get secret <name> -n <project> -o yaml`

### PVC stuck in Pending

* Ensure a default Storage Class exists: `oc get storageclass`
* Inspect PVC events: `oc describe pvc <pvc-name> -n <project>`
* For RWX, use a storage class that supports ReadWriteMany (e.g., NFS, CephFS).

### Model server cannot load from S3

* Confirm the Data Connection is attached to the deployment.
* Confirm Secret keys match what the image expects (e.g., `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`).
* Verify network access from the pod to the S3 endpoint.

---

## Next Steps

* **Explorer path:** Use Data Connections with RWO PVCs for individual workbenches.
* **Collaborator path:** Enable RWX storage and mount a shared "golden" dataset to multiple workbenches.
* **Engineer path:** Use OCI/Modelcar connections for production model serving and faster cold start.

For full explanations, well-lit paths, taxonomy, and lab steps, use the Antora build or the course content in `modules/chapter1/`.

---

## Additional Resources

* **OpenShift AI Documentation:** [Red Hat Documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai/)
* **RHOAI 3:** Ensure you use the connection-type protocol and annotations documented for your release.
