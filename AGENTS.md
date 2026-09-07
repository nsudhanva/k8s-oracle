# AGENTS.md - AI Assistant Guidelines for k8s-oracle

This document provides essential context, repository standards, and safety guidelines for AI assistants working on this repository.

## Core Philosophy

This repository is the single source of truth for the OKE Kubernetes cluster via Terraform and ArgoCD:

- **100% Declarative**: The repo represents the entire cluster state.
- **GitOps First**: All Kubernetes workloads and cluster resources MUST be managed through ArgoCD manifests in `argocd/`.
- **Infrastructure as Code**: All cloud infrastructure is provisioned through Terraform in `tf-oke/`.
- **Reproducible**: Any configuration or architectural adjustments must be committed here to ensure complete reproducibility.

---

## Project Overview

An **OKE (Oracle Kubernetes Engine) Basic cluster on Oracle Cloud Infrastructure (OCI) Always Free tier** configured with:

- **Terraform** for infrastructure provisioning
- **OKE Basic Cluster** - Free managed Kubernetes control plane
- **ARM-based worker nodes** - 2 nodes with 2 OCPU / 12GB RAM each (4 OCPUs, 24GB RAM total)
- **ArgoCD** for GitOps-based continuous delivery
- **Envoy Gateway** for ingress (Gateway API) with OCI flexible LB (lb, 10/10, free tier)
- **External Secrets Operator** with OCI Vault for automated secrets management
- **Cert Manager** for Let's Encrypt TLS certificates
- **External DNS** for Cloudflare DNS automation

---

## Critical Safety Rules

### 1. NEVER Commit Secrets

- `terraform.tfvars` contains sensitive credentials (always gitignored).
- `terraform.tfstate` is local (`tf-oke/backend.tf` backend block is commented out; the `oke-tfstate` bucket exists with versioning but is not wired as backend). Do not assume remote state.
- Cloudflare tokens, GitHub PATs, and passwords are in OCI Vault (`oke-secrets-vault`).
- App runtime secrets (DB password, Django key, market-data API keys) reach pods only through `ExternalSecret` refs (`argocd/apps/lakshmi/secret.yaml` to `lakshmi-secrets`). Never put values in ConfigMaps or manifests.
- Always check `git diff --staged` before committing (rendered `argocd/*.yaml` can contain live OCIDs, zone IDs, subnet IDs, emails).

### 2. NEVER Run `kubectl apply` Directly for Workloads

- All user-facing and application resources MUST be deployed via ArgoCD.
- Modify manifests under `argocd/` and push to Git.
- ArgoCD automatically reconciles and syncs changes.
- Direct imperative changes bypass GitOps and cause drift.

### 3. Terraform Safety

```bash
# ALWAYS run plan first
terraform plan -out=tfplan

# Review the plan carefully before applying
terraform apply tfplan

# NEVER run these without explicit confirmation:
# - terraform destroy
# - terraform apply -auto-approve
```

### 4. Guidelines & Best Practices

- Do not add inline comments to YAML manifests.
- Do not use manual `helm install`; let ArgoCD manage Helm releases declaratively.
- Research latest stable releases before introducing new dependencies or updating chart versions.
- Do not delete persistent volume claims (PVCs) without explicit user approval.
- Store sensitive values in OCI Vault and synchronize via External Secrets.

### 5. Database Permanence & Zero Data Loss Invariant

The PostgreSQL persistent volumes (such as `postgres-data-lakshmi-postgres-0` in `lakshmi`) store irreplaceable state, execution ledgers, and history.

- **NEVER Delete PVCs or PVs**: Under no circumstances should persistent volume claims, persistent volumes, or storage classes bound to databases be deleted or recreated.
- **NEVER Run Destructive Database Commands**: Commands like `flush`, `drop database`, `DROP TABLE`, or recreating StatefulSets with fresh storage are strictly prohibited.
- **Handling Crashes / Degraded Pods**: If a database pod fails or crashes:
  1. Diagnose non-destructively via logs (`kubectl logs`) and events (`kubectl describe`).
  2. Check secret synchronization (`ExternalSecret`) and network connectivity.
  3. Verify volume attachment in OCI Console / CSI driver (`csi-oci-node`).
  4. Always preserve the underlying block volume and data. Never attempt to resolve a crash by deleting the volume or resetting the database.

### 6. Argo CD 100% Synchronization Invariant

When debugging or diagnosing cluster issues with Argo CD:

- **Always verify 100% Sync First**: Before troubleshooting pod crashes, routing issues, or runtime drift, confirm that Argo CD is 100% synced with the application manifests, git repository, and underlying cloud infrastructure (`kubectl get application -A`).
- Never debug against an `OutOfSync`, syncing, or drifted Argo CD state. Always resolve repository drift or trigger a full synchronization first before inspecting runtime workloads.

---

## Repository Structure

```text
k8s-oracle/
├── tf-oke/                    # Terraform infrastructure code
│   ├── *.tf                   # cluster, network, vault, bucket, iam, identity, manifests, outputs
│   └── templates/manifests/   # ArgoCD manifest templates rendered by manifests.tf
├── argocd/                    # GitOps manifests (committed render output)
│   ├── applications.yaml      # 9 ArgoCD Applications (metrics-server, gateway-api-crds, cert-manager, external-dns, envoy-gateway, argocd-ingress, external-secrets, managed-secrets, lakshmi)
│   ├── apps/lakshmi/          # lakshmi workload (namespace, secret, postgres, server, client, docs, ingress)
│   └── infrastructure/        # cert-manager, envoy-gateway, external-dns, external-secrets, managed-secrets, argocd-ingress
├── .github/workflows/         # lint.yml (PR pre-commit)
├── AGENTS.md                  # Assistant guidelines and operational notes
└── README.md                  # Project overview and quick start
```

---

## OKE Cluster Configuration Defaults

- **Kubernetes Version**: 1.36.1 (live nodes `v1.36.1`, `kubectl v1.36.2` client)
- **ArgoCD**: installed from unpinned `argo-cd/stable/manifests/install.yaml`, no version pinned in repo
- **cert-manager**: v1.21.1
- **external-dns**: 1.21.1
- **envoy-gateway**: v1.9.1
- **external-secrets**: 2.10.0
- **gateway-api CRDs**: v1.6.1
- **metrics-server**: 3.14.0
- **Cluster Type**: BASIC_CLUSTER (free managed control plane)
- **Node Pool**: 2 ARM nodes (`VM.Standard.A1.Flex`)
- **Total Resources**: 4 OCPUs, 24GB RAM (maximizes Always Free tier)
- **Live endpoints (2026-09-06)**: flexible LB `129.80.2.214`, Gateway `public-gateway`, hostnames `cd.k8s.sudhanva.me` + `lakshmi.k8s.sudhanva.me`, 9/9 apps Synced/Healthy

---

## Operational Notes

### OCI Always Free Storage

- Free block storage is **200 GB total** across the tenancy (including boot volumes).
- 2× ARM nodes = 2× 47 GB boot volumes = 94 GB baseline → **~106 GB** available for PVCs.
- Postgres manifest `argocd/apps/lakshmi/postgres.yaml` requests `40Gi oci-bv RWO` with no VPU tuning; live PVC `postgres-data-lakshmi-postgres-0` is `Bound 50Gi` after in-place expansion. No automated backups by owner decision (keep block storage inside free tier). Keep manifest and live capacity in sync manually.

### ArgoCD Cluster Behavior

- `argocd/applications.yaml` declares platform applications. Applying updates: `kubectl apply -f argocd/applications.yaml`.
- ArgoCD self-healing reconciles imperative edits on managed resources back to the committed Git state.
- To make a persistent change, edit the YAML in `argocd/`, commit, push to Git, and allow ArgoCD to sync.
