---
title: Accessing the Cluster
---

Because the K3s Control Plane (`server` node) resides in a **Private Subnet**, you cannot connect to it directly from the internet. You must use the **Ingress Node** as a jump host (bastion).

## SSH Access

To SSH into the nodes:

1. **Ingress Node** (Public):
   ```bash
   ssh -i /path/to/key.pem ubuntu@<ingress-public-ip>
   ```

2. **Server Node** (Private) via Jump Host:
   ```bash
   ssh -i /path/to/key.pem -J ubuntu@<ingress-public-ip> ubuntu@10.0.2.10
   ```

3. **Worker Node** (Private) via Jump Host:
   ```bash
   ssh -i /path/to/key.pem -J ubuntu@<ingress-public-ip> ubuntu@10.0.2.235
   # (Check terraform output for exact IP)
   ```

## Kubectl Access

To use `kubectl` from your local machine:

### Option A: SSH Tunnel (Recommended)

Open a tunnel to the Kubernetes API port (6443):

```bash
ssh -L 6443:10.0.2.10:6443 -N -i /path/to/key.pem ubuntu@<ingress-public-ip>
```

Then, configure your local kubeconfig to point to `https://localhost:6443`. You can copy the kubeconfig from the server:

```bash
ssh -J ubuntu@<ingress-public-ip> ubuntu@10.0.2.10 "sudo cat /etc/rancher/k3s/k3s.yaml" > ~/.kube/config
# Edit ~/.kube/config to replace '127.0.0.1' with 'localhost' if needed, or keep as is.
```

### Option B: Remote Command Execution

For quick checks without a tunnel, you can run commands remotely:

```bash
ssh -J ubuntu@<ingress-public-ip> ubuntu@10.0.2.10 "sudo kubectl get pods -A"
```

## Argo CD UI

Argo CD is running on the cluster, but it is not exposed publicly by default for security (unless you configure Ingress for it).

To access the UI:

1. **Port Forward**:
   ```bash
   ssh -L 8080:localhost:8080 -J ubuntu@<ingress-public-ip> ubuntu@10.0.2.10 \
   "sudo kubectl port-forward svc/argocd-server -n argocd 8080:443"
   ```

2. **Open Browser**:
   Visit `https://localhost:8080`.

3. **Login**:
   - **Username**: `admin`
   - **Password**: Get it from the initial secret:
     ```bash
     ssh -J ubuntu@<ingress-public-ip> ubuntu@10.0.2.10 \
     "sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
     ```
