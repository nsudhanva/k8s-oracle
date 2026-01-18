---
title: Access OKE Cluster - kubectl Setup
description: Connect to OKE Kubernetes cluster using OCI CLI. Setup local kubectl access to the control plane.
---

The OKE control plane is managed by Oracle and accessible via the public endpoint.

## Kubectl Access

The easiest way to access the cluster is using the OCI CLI to generate a kubeconfig file.

### Prerequisites

- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) installed and configured
- `kubectl` installed

### Generate Kubeconfig

```bash
# Get Cluster ID
CLUSTER_ID=$(terraform -chdir=tf-oke output -raw cluster_id)
REGION=$(terraform -chdir=tf-oke output -raw region)

# Generate kubeconfig
oci ce cluster create-kubeconfig \
  --cluster-id $CLUSTER_ID \
  --file $HOME/.kube/config \
  --region $REGION \
  --token-version 2.0.0 \
  --kube-endpoint PUBLIC_ENDPOINT
```

### Verify Access

```bash
kubectl get nodes
```

Expected output:
```text
NAME          STATUS   ROLES   AGE   VERSION
10.0.10.x     Ready    node    5m    v1.32.1
10.0.10.y     Ready    node    5m    v1.32.1
```

## Argo CD UI

### Via Public Ingress

If argocd-ingress is configured:

```text
https://cd.<your-domain>
```

### Via Port Forward

If ingress is not working, you can port-forward locally:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open `https://localhost:8080` in a browser.

### Credentials

Username: `admin`

Password:

```bash
kubectl -n argocd get secret argocd-secret -o jsonpath='{.data.admin\.password}' | base64 -d
```
Note: The secret name is `argocd-secret` and key is `admin.password` (synced via External Secrets), OR `argocd-initial-admin-secret` if using default install. Since we sync the password hash, Argo CD uses the updated password.

## Troubleshooting

### Connection Refused

Ensure your IP address is allowed if you have restricted the cluster endpoint access (though Basic Cluster usually has public endpoint open by default or controlled by VCN security lists).

### OCI CLI Errors

Ensure your OCI config is correct:
```bash
oci setup repair
```
