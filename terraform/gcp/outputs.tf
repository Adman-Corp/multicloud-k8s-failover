# GKE cluster outputs
output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_id" {
  description = "Resource ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubernetes configuration file (YAML)"
  value       = <<EOT
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${google_container_cluster.primary.master_auth[0].cluster_ca_certificate}
    server: https://${google_container_cluster.primary.endpoint}
  name: ${google_container_cluster.primary.name}
contexts:
- context:
    cluster: ${google_container_cluster.primary.name}
    user: ${google_container_cluster.primary.name}
  name: ${google_container_cluster.primary.name}
current-context: ${google_container_cluster.primary.name}
kind: Config
users:
- name: ${google_container_cluster.primary.name}
  user:
    auth-provider:
      name: gcp
EOT
  sensitive   = true
}

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "zone" {
  description = "GCP zone"
  value       = var.zone
}

output "vpc_name" {
  description = "Name of the VPC"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "workload_identity_pool" {
  description = "Workload Identity pool for External Secrets"
  value       = "${var.project_id}.svc.id.goog"
}

output "external_dns_namespace" {
  description = "Namespace where external-dns is installed"
  value       = helm_release.external_dns.namespace
}

output "external_dns_helm_chart_version" {
  description = "External DNS Helm chart version"
  value       = helm_release.external_dns.version
}

output "argocd_namespace" {
  description = "Namespace where Argo CD is installed"
  value       = helm_release.argocd.namespace
}

output "argocd_helm_chart_version" {
  description = "Argo CD Helm chart version"
  value       = helm_release.argocd.version
}

output "node_pool_name" {
  description = "Name of the node pool"
  value       = google_container_node_pool.primary_nodes.name
}
