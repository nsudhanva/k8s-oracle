---
title: "Guide: K3s on OCI Always Free"
description: "A complete guide to standing up a High-Availability K3s cluster on Oracle Cloud Infrastructure's Always Free tier."
---

This guide documents how to provision, bootstrap, and configure a production-ready K3s cluster on Oracle Cloud Infrastructure (OCI) using the Always Free tier (Ampere A1 Compute).

## Architecture

We utilize the generous OCI Always Free tier resources to create a 3-node cluster:

* **Ingress Node**: Dedicated entry point for traffic (Envoy Gateway).
* **Server Node**: Control plane (K3s Server).
* **Worker Node**: Application workloads.

**Resources:**

* **Compute**: 3x Ampere A1 instances (split OCPUs and RAM to fit within the 4 OCPU / 24GB IO Free Limit).
* **OS**: Ubuntu 22.04 Minimal (ARM64).
* **Network**: VCN with public subnets.

## 1. Infrastructure (Terraform)

The `tf-k3s` directory contains Terraform code to provision the OCI environment.

### Prerequisites

* OCI Account with API Keys configured.
* Terraform installed.
* `terraform.tfvars` populated with your OCI Tenancy OCID, User OCID, and SSH Keys.

### Configuration Highlights

* **VCN & Subnets**: A Virtual Cloud Network (`10.0.0.0/16`) with a public subnet (`10.0.1.0/24`).
* **Security Lists**:
  * **Internet Access**: Ingress ports 80 & 443 open to `0.0.0.0/0`.
  * **NodePorts**: Range `30000-32767` open for Kubernetes services.
  * **Internal**: Full communication allowed within `10.0.0.0/16`.

## 2. Bootstrapping (Ansible)

Once infrastructure is provisioned, Ansible configures the nodes.

**Key Roles:**

* **Base**: Updates packages, configures `netfilter-persistent` (important for firewall persistence).
* **Kubernetes**: Installs K3s using the official script.
  * *Server*: Initialized with `--cluster-init`.
  * *Agents*: Joined using the K3s token.

## 3. GitOps (Argo CD)

We use the **App of Apps** pattern.

1. **Bootstrap**: Apply `argocd/install.yaml` manually or via script.
2. **Parent App**: `argocd/applications.yaml` defines the root application pointing to this repository.
3. **Sync**: Argo CD automatically syncs infrastructure apps (Cert Manager, Envoy Gateway, etc.) and payload apps (Docs, etc.).

## 4. Ingress & Networking (Critical Configuration)

Getting ingress working reliably on OCI requires specific handling of networking and firewalls.

### Envoy Gateway Setup

We use Envoy Gateway as the implementation of the Kubernetes Gateway API.

**Configuration Strategy: `hostPort`**
To avoid DNS resolution issues common with `hostNetwork` on OCI (where the host resolver doesn't know about Kubernetes ClusterIPs), we configure the Envoy Proxy using **HostPort** mapping:

* **Service Type**: `ClusterIP` (Internal only).
* **Port Mapping**: The Envoy container binds ports `80` and `443` directly to the Host's interface using `hostPort`.
* **Benefit**: The Pod remains in the Cluster Network (Overlay), ensuring it can resolve internal services (like `envoy-gateway` controller) via CoreDNS, while still attracting external traffic.

### Firewall & Overlay Network

OCI Ubuntu images often ship with strict `iptables` rules that can block Kubernetes Overlay traffic (VXLAN).

**Required Fixes:**

1. **Allow Overlay**: Explicitly allow traffic from the VCN CIDR (`10.0.0.0/16`) in the `INPUT` chain.

    ```bash
    iptables -I INPUT 6 -s 10.0.0.0/16 -j ACCEPT
    ```

    *Why*: Without this, Node-to-Node communication (like Ingress Node reaching CoreDNS on Server Node) will timeout.

2. **Allow External Traffic**: Explicitly allow TCP 80/443 in the `INPUT` chain.

    ```bash
    iptables -I INPUT 6 -p tcp --dport 80 -j ACCEPT
    iptables -I INPUT 7 -p tcp --dport 443 -j ACCEPT
    ```

    *Why*: Even with `hostPort`, strict default `REJECT` policies can sometimes drop DNAT'd packets. Explicit acceptance ensures reliability.

## 5. HTTPS & Certificate Management

We use **cert-manager** with **Let's Encrypt** for automatic TLS.

* **ClusterIssuer**: Configured with the **Cloudflare DNS-01** solver. This allows issuing certificates for servers behind firewalls or without public Load Balancers.
* **Secret Management**: The Cloudflare API Token Secret (`cloudflare-api-token-secret`) **must** reside in the `cert-manager` namespace for the `ClusterIssuer` to access it.

### Verification

Once configured:

1. **DNS**: `external-dns` automatically updates Cloudflare records to point to the Ingress Node IP.
2. **Certificates**: A `Certificate` resource creates a TLS secret.
3. **Gateway**: The Envoy Gateway listener becomes `Programmed` and starts terminating TLS on port 443.

## Troubleshooting Cheatsheet

| Symptom | Probable Cause | Fix |
| :--- | :--- | :--- |
| **Envoy Pod `NoResources` / Startup Fail** | Connectivity timeout to Controller (xDS). | Check Overlay Firewall rules (`iptables -L INPUT`). Ensure Pod is NOT using `hostNetwork`. |
| **External `Connection Refused` on Port 80** | Node Firewall blocking port. | Add explicit `ACCEPT` rule for port 80/443 in `iptables`. |
| **Cert Manager `IssuerNotFound`** | Secret in wrong namespace. | Move `cloudflare-api-token-secret` to `cert-manager` namespace. |
