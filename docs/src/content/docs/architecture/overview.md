---
title: OKE Cluster Architecture on Oracle Cloud
description: Complete architecture of OKE Kubernetes cluster on OCI Free tier. Includes Ampere A1 ARM64 instances, GitOps with ArgoCD, and Gateway API ingress.
---

This cluster runs on Oracle Cloud Infrastructure's Free tier using OKE (Oracle Kubernetes Engine) Basic Cluster.

```mermaid
graph TB
    subgraph Internet
        User((User))
        DNS[Cloudflare DNS]
    end

    subgraph OCI["Oracle Cloud Infrastructure"]
        subgraph Public["Public Subnet (10.0.1.0/24)"]
            LB[OCI Load Balancer]
        end

        subgraph Private["Private Subnet (10.0.2.0/24)"]
            Worker1[Worker Node 1]
            Worker2[Worker Node 2]
        end
        
        CP[OKE Control Plane<br/>Managed]
    end

    User -->|HTTPS| DNS
    DNS -->|A Record| LB
    LB -->|Traffic| Worker1
    LB -->|Traffic| Worker2
    CP -.->|Manages| Worker1
    CP -.->|Manages| Worker2
```

## Node Topology

| Node | OCPUs | RAM | Subnet | Purpose |
|------|-------|-----|--------|---------|
| Control Plane | - | - | Managed | OKE Basic Control Plane |
| Worker 1 | 2 | 12GB | Private (10.0.2.0/24) | Application workloads |
| Worker 2 | 2 | 12GB | Private (10.0.2.0/24) | Application workloads |

## Infrastructure

Terraform provisions the OCI environment in `tf-oke/`.

### Network

- VCN CIDR: 10.0.0.0/16
- Public subnet: 10.0.1.0/24 (Load Balancers)
- Private subnet: 10.0.2.0/24 (Worker Nodes)
- Internet gateway for public subnet
- NAT gateway for private subnet outbound access

### Security Lists

- Load Balancer ports 80 and 443 from 0.0.0.0/0
- SSH access to bastion (if configured)
- Full VCN internal communication

## Bootstrapping

Terraform provisions the OKE cluster and node pool. Once the cluster is active, you configure `kubectl` and install Argo CD manually.

```mermaid
sequenceDiagram
    participant TF as Terraform
    participant OCI as OCI API
    participant OKE as OKE Cluster
    participant Argo as Argo CD
    participant GH as GitHub

    TF->>OCI: Create VCN, Subnets, OKE Cluster
    OCI->>OKE: Provision Control Plane & Nodes

    Note over OKE: Cluster Active

    User->>OKE: Install Argo CD
    User->>OKE: Apply Root Application

    Argo->>GH: Fetch manifests
    Argo->>OKE: Deploy applications
    Note over Argo,OKE: Continuous sync loop
```

## GitOps

Argo CD manages all cluster resources using the App-of-Apps pattern.

```mermaid
flowchart LR
    subgraph GitHub
        Repo[(k3s-oracle<br/>Repository)]
    end

    subgraph Cluster["OKE Cluster"]
        subgraph ArgoCD["Argo CD"]
            Root[Root App]
            Apps[Application<br/>Manifests]
        end

        subgraph Infra["Infrastructure Apps"]
            CRDs[Gateway API CRDs]
            CM[Cert Manager]
            EG[Envoy Gateway]
            ED[External DNS]
        end

        subgraph UserApps["User Applications"]
            Docs[Docs Site]
            ArgoUI[Argo CD UI]
        end
    end

    Repo -->|sync| Root
    Root -->|manages| Apps
    Apps -->|deploys| CRDs
    Apps -->|deploys| CM
    Apps -->|deploys| EG
    Apps -->|deploys| ED
    Apps -->|deploys| Docs
    Apps -->|deploys| ArgoUI
```

### Applications

| Application | Purpose |
|-------------|---------|
| gateway-api-crds | Gateway API CRDs |
| cert-manager | TLS certificate automation |
| external-dns | Cloudflare DNS management |
| external-secrets | OCI Vault integration |
| managed-secrets | Vault secret sync configuration |
| envoy-gateway | Gateway API implementation |
| argocd-self-managed | Self-managed Argo CD |
| argocd-ingress | Argo CD UI ingress |
| docs-app | Documentation website |

## Ingress

Envoy Gateway implements the Kubernetes Gateway API. It provisions an OCI Load Balancer to handle external traffic.

```mermaid
flowchart LR
    subgraph Internet
        Browser((Browser))
    end

    subgraph OCI["OCI"]
        LB[Load Balancer]
    end

    subgraph Cluster["OKE Cluster"]
        GW[public-gateway]
        HR1[HTTPRoute<br/>docs]
        HR2[HTTPRoute<br/>argocd]
        SVC1[docs Service]
        SVC2[argocd Service]
        POD1[docs Pod]
        POD2[argocd Pod]
    end

    Browser -->|HTTPS| LB
    LB --> GW
    GW --> HR1
    GW --> HR2
    HR1 --> SVC1
    HR2 --> SVC2
    SVC1 --> POD1
    SVC2 --> POD2
```

## TLS Certificates

Cert Manager issues Let's Encrypt certificates using HTTP-01 challenges via Gateway API. External DNS updates Cloudflare A records to point to the ingress node public IP.

```mermaid
sequenceDiagram
    participant CM as Cert Manager
    participant LE as Let's Encrypt
    participant GW as Gateway
    participant CF as Cloudflare
    participant ED as External DNS

    ED->>CF: Create A record (domain → ingress IP)
    CM->>LE: Request certificate
    LE->>GW: HTTP-01 challenge request
    GW->>CM: Serve challenge token
    LE->>CM: Certificate issued
    CM->>GW: Store TLS secret
    Note over GW: HTTPS enabled
```
