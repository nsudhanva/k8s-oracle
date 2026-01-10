---
title: GitOps & Argo CD
---

# GitOps with Argo CD

Everything in this cluster is managed via Argo CD following the **App-of-Apps** pattern.

## Directory Structure

```
argocd/
├── kustomization.yaml          # Root kustomization
├── applications.yaml           # All Argo CD Application definitions
├── infrastructure/             # System components
│   ├── argocd/                 # Self-managed Argo CD Helm release
│   ├── argocd-ingress/         # Exposes Argo CD UI via Gateway API
│   ├── cert-manager/           # TLS certificate automation
│   ├── envoy-gateway/          # Gateway API implementation
│   └── external-dns/           # Cloudflare DNS automation
└── apps/                       # User applications
    └── docs/                   # Documentation site
```

## Argo CD Applications

The cluster runs these applications (all synced automatically):

| Application | Purpose | Namespace |
|------------|---------|-----------|
| `gateway-api-crds` | Gateway API CRDs from upstream | (cluster-wide) |
| `cert-manager` | TLS certificate automation | `cert-manager` |
| `external-dns` | Cloudflare DNS record management | `external-dns` |
| `envoy-gateway` | Gateway API controller | `envoy-gateway-system` |
| `argocd-self-managed` | Self-managed Argo CD | `argocd` |
| `argocd-ingress` | Argo CD UI ingress | `argocd` |
| `docs-app` | Documentation website | `default` |

## Secrets Management

We use standard Kubernetes Secrets for simplicity in this "Always Free" demo.

- Cloudflare API tokens are passed via Terraform to the K3s server manifests on boot.
- These are stored in the `cert-manager` and `external-dns` namespaces.

## Handling Sync Issues

If an app stays in `OutOfSync` or `Unknown`:

1. Check CRDs: Some apps depend on CRDs (like Gateway API) that must be installed first.
2. Hard Refresh:

   ```bash
   kubectl patch app <app-name> -n argocd --type merge -p '{"metadata": {"annotations": {"argocd.argoproj.io/refresh": "hard"}}}'
   ```
