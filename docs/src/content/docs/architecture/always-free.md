---
title: Oracle Cloud Always Free Tier for Kubernetes
description: Run K3s Kubernetes for free on OCI Always Free tier. Get 4 ARM64 OCPUs, 24GB RAM, 200GB storage, and 10TB egress monthly - perfect for a 3-node cluster.
---

This cluster runs entirely within Oracle Cloud Infrastructure's Always Free tier limits.

```mermaid
pie showData
    title OCI Always Free Resource Allocation
    "k3s-server (2 OCPU, 12GB)" : 50
    "k3s-ingress (1 OCPU, 6GB)" : 25
    "k3s-worker (1 OCPU, 6GB)" : 25
```

## Resource Allocation

OCI Always Free provides 4 OCPUs and 24GB RAM for Ampere A1 instances. This cluster divides these resources across three nodes:

| Node | OCPUs | RAM | Purpose |
|------|-------|-----|---------|
| k3s-ingress | 1 | 6GB | NAT gateway, ingress proxy |
| k3s-server | 2 | 12GB | Control plane, Argo CD |
| k3s-worker | 1 | 6GB | Application workloads |

Total: 4 OCPUs, 24GB RAM (exactly at the limit)

```mermaid
graph LR
    subgraph Free["Always Free (4 OCPU, 24GB)"]
        I[Ingress<br/>1 OCPU<br/>6GB]
        S[Server<br/>2 OCPU<br/>12GB]
        W[Worker<br/>1 OCPU<br/>6GB]
    end

    subgraph Used["Used: 4 OCPU, 24GB"]
        Total[100% Utilized]
    end

    I --> Total
    S --> Total
    W --> Total
```

## Always Free Components

### Compute

Ampere A1 Flex instances are ARM64-based. Container images must support the `linux/arm64` architecture.

### Networking

- 1 VCN with up to 2 subnets
- 1 Internet Gateway
- 1 Network Load Balancer (Always Free includes 1 flexible NLB)
- Security lists and route tables
- No NAT Gateway (implemented in software on ingress node)

### Storage

- 200GB total block volume storage
- Boot volumes count against this limit
- Each node uses a 50GB boot volume (150GB total)

### Bandwidth

- 10TB outbound data transfer per month
- Unlimited inbound

## Cost Avoidance

This cluster replaces paid OCI services with free alternatives:

```mermaid
flowchart LR
    subgraph Paid["Paid Services (Avoided)"]
        NAT[OCI NAT Gateway<br/>~$32/month]
        BV[Block Volumes<br/>~$0.02/GB/month]
    end

    subgraph Free["Free Alternatives (Used)"]
        NLB[Network Load Balancer<br/>Always Free]
        IPT[iptables NAT<br/>on Ingress Node]
        LP[local-path-provisioner<br/>on Boot Volume]
    end

    NAT -.->|replaced by| IPT
    BV -.->|replaced by| LP
```

### Network Load Balancer

OCI Always Free includes 1 Flexible Network Load Balancer. This cluster uses it to provide a stable public IP for ingress traffic:

```mermaid
flowchart LR
    Internet((Internet)) -->|:443| NLB[Network Load Balancer]
    NLB -->|TCP forward| Ingress[Ingress Node<br/>hostPort]
    Ingress --> Envoy[Envoy Pod]
    Envoy --> Apps[Applications]
```

Benefits of using the NLB:

- Stable public IP (doesn't change if ingress node is replaced)
- Health checks on backend
- Can add more ingress nodes later for HA

### No NAT Gateway

OCI NAT Gateways are not included in Always Free. The ingress node runs iptables masquerade to provide outbound internet access for the private subnet.

```mermaid
flowchart LR
    Private[Private Subnet<br/>10.0.2.0/24] -->|outbound| Ingress[Ingress Node<br/>iptables MASQUERADE]
    Ingress -->|SNAT| IGW[Internet Gateway]
    IGW --> Internet((Internet))
```

### No Block Volumes

Additional block volumes would consume the 200GB limit. K3s uses local-path-provisioner for persistent storage, storing data on the node's boot volume.

## Staying Within Limits

### Instance Sizing

Terraform enforces the correct instance shapes. Do not manually resize instances in the OCI Console.

### Region Selection

Ampere A1 capacity varies by region. US-Ashburn-1 and EU-Frankfurt-1 typically have better availability. If provisioning fails with "Out of Capacity," try a different availability domain or region.

### Monitoring Usage

Check your tenancy limits in the OCI Console under Governance > Limits, Quotas and Usage. Filter by "compute" to see Ampere A1 availability.
