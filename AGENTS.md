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
- **Envoy Gateway** for ingress (Gateway API) with OCI Network Load Balancer
- **External Secrets Operator** with OCI Vault for automated secrets management
- **Cert Manager** for Let's Encrypt TLS certificates
- **External DNS** for Cloudflare DNS automation

---

## Critical Safety Rules

### 1. NEVER Commit Secrets

- `terraform.tfvars` contains sensitive credentials (always gitignored).
- `terraform.tfstate` contains infrastructure state with secrets (persisted in secure OCI Object Storage).
- Cloudflare tokens, GitHub PATs, and passwords are encrypted in OCI Vault.
- Always check `git diff --staged` before committing.

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

---

## Repository Structure

```text
k8s-oracle/
├── tf-oke/                    # Terraform infrastructure code
│   ├── *.tf                   # Terraform configuration files
│   └── templates/manifests/   # ArgoCD manifest templates
├── argocd/                    # GitOps manifests
│   ├── applications.yaml      # ArgoCD Application declarations
│   └── infrastructure/        # Platform components (cert-manager, envoy-gateway, etc.)
├── .github/workflows/         # GitHub Actions workflows (linting, CI)
├── AGENTS.md                  # Assistant guidelines and operational notes
└── README.md                  # Project overview and quick start
```

---

## OKE Cluster Configuration Defaults

- **Kubernetes Version**: 1.36.1
- **ArgoCD**: v3.5.2
- **cert-manager**: v1.21.1
- **external-dns**: 1.21.1
- **envoy-gateway**: v1.9.1
- **external-secrets**: 2.10.0
- **gateway-api CRDs**: v1.6.1
- **metrics-server**: 3.14.0
- **Cluster Type**: BASIC_CLUSTER (free managed control plane)
- **Node Pool**: 2 ARM nodes (`VM.Standard.A1.Flex`)
- **Total Resources**: 4 OCPUs, 24GB RAM (maximizes Always Free tier)

---

## Operational Notes

### OCI Always Free Storage

- Free block storage is **200 GB total** across the tenancy (including boot volumes).
- 2× ARM nodes = 2× 47 GB boot volumes = 94 GB baseline → **~106 GB** available for PVCs.
- Set persistent volume claims to VPU=0 (Lower Cost) to remain within free tier limits.

### ArgoCD Cluster Behavior

- `argocd/applications.yaml` declares platform applications. Applying updates: `kubectl apply -f argocd/applications.yaml`.
- ArgoCD self-healing reconciles imperative edits on managed resources back to the committed Git state.
- To make a persistent change, edit the YAML in `argocd/`, commit, push to Git, and allow ArgoCD to sync.
