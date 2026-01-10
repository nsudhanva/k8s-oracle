---
title: Cluster Setup Guide
---

# Initial Cluster Setup

This page covers how to stand up the cluster from zero using Terraform.

## 1. Prerequisites

- OCI Account (Always Free).
- Cloudflare Domain & API Token.
- `terraform` and `gh` (GitHub CLI) installed locally.

## 2. Configuration

Create `tf-k3s/terraform.tfvars`. Ensure the following variables are set:

- `tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key_path`: Your OCI credentials.
- `cloudflare_api_token`: Cloudflare API Token (Edit Zone DNS).
- `cloudflare_zone_id`: The Zone ID for your domain (found on the Cloudflare dashboard overview).
- `domain_name`: Your target domain (e.g., `example.com`).
- `acme_email`: Email for Let's Encrypt notifications.
- `git_repo_url`: The HTTPS URL of **your fork** of this repository.
- `git_pat`: Your GitHub Personal Access Token (Classic) with `repo` and `read:packages` scope.
- `git_username`: Your GitHub username.
- `ssh_public_key_path`: Absolute path to your OCI-compatible SSH public key (e.g., `~/.oci/oci_api_key_public.pem` or `~/.ssh/id_rsa.pub`).

> **Note**: This setup uses the **HTTP-01** challenge for SSL certificates to avoid complex Cloudflare permission issues. Ensure your `cloudflare_api_token` has at least `Zone:Read` and `DNS:Edit` permissions.

## 3. Provisioning

Run Terraform to provision infrastructure and generate the Kubernetes manifests (with your domain and config).

```bash
cd tf-k3s
terraform init
terraform apply -auto-approve
```

**CRITICAL STEP**: Terraform generates the GitOps manifests in the `argocd/` directory. You **MUST** commit and push these changes so the cluster can sync them.

```bash
cd ..
git add argocd/
git commit -m "Configure cluster manifests"
git push
```

## 4. Bootstrapping (Automatic)

Terraform uses `cloud-init` to:

1. Set up software NAT on the Ingress node.
2. Install K3s on the Server node.
3. Install K3s Agent on the Worker node.
4. Install Argo CD and the Root Application.

**Time to wait**: ~5 minutes for all nodes to join and Argo CD to start syncing.

## 5. Verification

After waiting for bootstrap to complete, verify everything is working.

### Check Nodes

```bash
# Get connection info
cd tf-k3s && terraform output

# SSH to server and check nodes
ssh -J ubuntu@<ingress-public-ip> ubuntu@10.0.2.10 "sudo kubectl get nodes"
```

Expected output (all nodes should be `Ready`):
```
NAME       STATUS   ROLES           AGE   VERSION
ingress    Ready    <none>          5m    v1.34.3+k3s1
server     Ready    control-plane   5m    v1.34.3+k3s1
worker-1   Ready    <none>          5m    v1.34.3+k3s1
```

### Check Argo CD Applications

```bash
ssh -J ubuntu@<ingress-public-ip> ubuntu@10.0.2.10 "sudo kubectl get applications -n argocd"
```

Expected output (all should be `Synced` and `Healthy`):
```
NAME                  SYNC STATUS   HEALTH STATUS
argocd-ingress        Synced        Healthy
argocd-self-managed   Synced        Healthy
cert-manager          Synced        Healthy
docs-app              Synced        Healthy
envoy-gateway         Synced        Healthy
external-dns          Synced        Healthy
gateway-api-crds      Synced        Healthy
root-app              Synced        Healthy
```

### Check All Pods

```bash
ssh -J ubuntu@<ingress-public-ip> ubuntu@10.0.2.10 "sudo kubectl get pods -A"
```

All pods should be `Running` (except completed jobs).

### Verify DNS & TLS

After a few minutes, your domain should be accessible:

```bash
# Check DNS record
dig +short k3s.yourdomain.com

# Test HTTPS (should return 200)
curl -I https://k3s.yourdomain.com
```

## 6. Next Steps

Once verified:

1. [Set up local kubectl access](/operation/accessing-cluster/)
2. [Deploy your own applications](/operation/deploying-apps/)
3. [Access Argo CD UI](/operation/accessing-cluster/#argo-cd-ui)
