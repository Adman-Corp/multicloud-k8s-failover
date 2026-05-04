# AKS cluster outputs
output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_id" {
  description = "Resource ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubernetes configuration file (YAML)"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_name" {
  description = "Name of the AKS subnet"
  value       = azurerm_subnet.aks.name
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for External Secrets"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

# SSH private key (sensitive) - only if needed for debugging
output "ssh_private_key_pem" {
  description = "Generated SSH private key (PEM format)"
  value       = tls_private_key.aks_ssh.private_key_pem
  sensitive   = true
}

output "ssh_public_key_openssh" {
  description = "Generated SSH public key (OpenSSH format)"
  value       = tls_private_key.aks_ssh.public_key_openssh
}