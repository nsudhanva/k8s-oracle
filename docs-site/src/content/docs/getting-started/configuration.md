---
title: Configuration Reference
---

This project uses a `terraform.tfvars` file to configure the deployment. Do not commit this file to Git!

## Required Variables

Create `tf-k3s/terraform.tfvars` with the following:

```hcl
# --- OCI Identity ---
tenancy_ocid     = "ocid1.tenancy.oc1..aaaa..."
user_ocid        = "ocid1.user.oc1..aaaa..."
fingerprint      = "12:34:56:..."
private_key_path = "/path/to/your/oci_api_key.pem"
compartment_ocid = "ocid1.compartment.oc1..aaaa..."
region           = "us-ashburn-1"

# --- Cluster & Network ---
# Your SSH Public Key for instance access (OpenSSH format)
ssh_public_key_path = "/Users/you/.oci/oci_api_key_public.pem"

# Source CIDR allowed to SSH into the Bastion/Ingress node (Default: 0.0.0.0/0)
ssh_source_cidr     = "0.0.0.0/0"

# --- Domain & DNS ---
cloudflare_api_token = "your-cloudflare-token"
cloudflare_zone_id   = "your-zone-id" # Required for ExternalDNS
domain_name          = "k3s.yourdomain.com"
acme_email           = "admin@yourdomain.com"

# --- GitOps ---
git_repo_url  = "https://github.com/your-username/k3s-oracle.git"
git_username  = "your-username"
git_pat       = "ghp_..."
git_repo_name = "k3s-oracle" # Default
```

## Variable Details

| Variable | Description |
| :--- | :--- |
| `ssh_public_key_path` | Path to the **public** key that will be added to `~/.ssh/authorized_keys` on all nodes. **Must be OpenSSH format** (starts with `ssh-rsa` or `ssh-ed25519`), NOT PEM format. |
| `cloudflare_zone_id` | The alphanumeric Zone ID from your Cloudflare Dashboard (Overview tab). Required because API Tokens with limited scope sometimes cannot discover the Zone ID automatically. |
| `git_pat` | Your GitHub Personal Access Token. It is injected into the cluster as a Secret to allow Argo CD to pull from your private repo. |
