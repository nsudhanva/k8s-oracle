variable "tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
}

variable "user_ocid" {
  description = "OCI User OCID"
  type        = string
}

variable "fingerprint" {
  description = "OCI API Key fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "Path to OCI API private key"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
}

variable "compartment_ocid" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH Public Key to use for instances."
  type        = string
  default     = "./oci_key.pub"
}

variable "ssh_source_cidr" {
  description = "CIDR block allowed to SSH into the Ingress node. Defaults to 0.0.0.0/0 (open to world)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone.DNS permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the cluster"
  type        = string
}

variable "git_repo_url" {
  description = "Git repository URL for ArgoCD"
  type        = string
}

variable "git_pat" {
  description = "GitHub Personal Access Token for cloning the private repository."
  type        = string
  sensitive   = true
}

variable "git_username" {
  description = "GitHub Username for the PAT."
  type        = string
  default     = "git"
}

variable "git_repo_name" {
  description = "The repository name (e.g. k8s-oracle) to construct GHCR image paths."
  type        = string
  default     = "k8s-oracle"
}

variable "kubernetes_version" {
  description = "Kubernetes version for OKE cluster"
  type        = string
  default     = "1.32.1"
}

variable "node_pool_size" {
  description = "Number of nodes in the OKE node pool"
  type        = number
  default     = 2
}

variable "node_ocpus" {
  description = "Number of OCPUs per node (total across all nodes must not exceed 4 for free tier)"
  type        = number
  default     = 2
}

variable "node_memory_in_gbs" {
  description = "Memory in GB per node (total across all nodes must not exceed 24 for free tier)"
  type        = number
  default     = 12
}

variable "common_tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default = {
    Project     = "oke-oracle-free"
    ManagedBy   = "Terraform"
    Environment = "Production"
  }
}

variable "argocd_admin_password" {
  description = "ArgoCD admin password to store in OCI Vault"
  type        = string
  sensitive   = true
}

variable "argocd_admin_password_hash" {
  description = "Bcrypt hash of ArgoCD admin password for argocd-secret"
  type        = string
  sensitive   = true
}

variable "git_email" {
  description = "Email address for GitHub container registry authentication"
  type        = string
}

variable "load_balancer_ip" {
  description = "LoadBalancer IP for the Envoy Gateway (set after initial deployment)"
  type        = string
  default     = ""
}

variable "gemma_api_key" {
  description = "API key for authenticating Gemma LLM API requests"
  type        = string
  sensitive   = true
  default     = ""
}

variable "huggingface_token" {
  description = "HuggingFace API token for downloading gated models (e.g., Gemma 3)"
  type        = string
  sensitive   = true
}

variable "oidc_client_id" {
  description = "OCI Identity Domain OIDC client ID for Open WebUI (from OCI Console after app creation)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "oidc_client_secret" {
  description = "OCI Identity Domain OIDC client secret for Open WebUI (from OCI Console after app creation)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "oidc_provider_url" {
  description = "OCI Identity Domain OIDC provider URL (e.g., https://idcs-xxx.identity.oraclecloud.com)"
  type        = string
  default     = ""
}

