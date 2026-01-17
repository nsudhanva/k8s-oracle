output "cluster_id" {
  value       = oci_containerengine_cluster.oke_cluster.id
  description = "OKE Cluster OCID"
}

output "cluster_kubernetes_version" {
  value       = oci_containerengine_cluster.oke_cluster.kubernetes_version
  description = "Kubernetes version of the OKE cluster"
}

output "cluster_endpoints" {
  value       = oci_containerengine_cluster.oke_cluster.endpoints
  description = "OKE Cluster endpoints"
}

output "node_pool_id" {
  value       = oci_containerengine_node_pool.oke_node_pool.id
  description = "OKE Node Pool OCID"
}

output "domain_url" {
  value       = "https://${var.domain_name}"
  description = "Primary domain URL"
}

output "kubeconfig_command" {
  value       = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.oke_cluster.id} --file $HOME/.kube/config --region ${var.region} --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT"
  description = "Command to generate kubeconfig"
}

output "next_steps" {
  value       = <<EOT
1. Generate kubeconfig:
   oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.oke_cluster.id} --file $HOME/.kube/config --region ${var.region} --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT

2. Push the generated ArgoCD manifests to Git:
   cd ../argocd && git add . && git commit -m "Update ArgoCD manifests" && git push

3. Install ArgoCD on the cluster:
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

4. Apply the root ArgoCD application:
   kubectl apply -f ../argocd/applications.yaml

5. Wait for applications to sync and verify:
   kubectl get applications -n argocd
EOT
  description = "Post-deployment steps"
}
