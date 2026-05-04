# Azure region
variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "eastus"
}

# Resource group name
variable "resource_group_name" {
  description = "Name of the resource group to create"
  type        = string
  default     = "mc-aks-rg"
}

# Cluster name
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "mc-aks"
}

# Kubernetes version
variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.35"
}

variable "external_dns_cloudflare_api_token" {
  description = "Cloudflare API token used by external-dns"
  type        = string
  sensitive   = true
}

variable "external_dns_chart_version" {
  description = "External DNS Helm chart version"
  type        = string
  default     = "1.21.1"
}

variable "external_dns_namespace" {
  description = "Namespace where external-dns is installed"
  type        = string
  default     = "external-dns"
}

variable "external_dns_domain_filters" {
  description = "DNS suffixes managed by external-dns"
  type        = list(string)
  default     = ["admancorp.com"]
}

variable "external_dns_cloudflare_zone_id" {
  description = "Optional Cloudflare zone ID filter for external-dns"
  type        = string
  default     = null
}

variable "argocd_hostname" {
  description = "DNS hostname managed by external-dns for the Argo CD server service"
  type        = string
  default     = null
}

variable "argocd_certificate_name" {
  description = "cert-manager Certificate name for Argo CD server TLS"
  type        = string
  default     = "argocd-server-tls"
}

variable "cert_manager_chart_version" {
  description = "cert-manager Helm chart version"
  type        = string
  default     = "v1.20.2"
}

variable "cert_manager_namespace" {
  description = "Namespace where cert-manager is installed"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_acme_email" {
  description = "ACME email address used by cert-manager for Let's Encrypt"
  type        = string
}

variable "cert_manager_cluster_issuer_name" {
  description = "ClusterIssuer name for Let's Encrypt"
  type        = string
  default     = "letsencrypt-production"
}

variable "cert_manager_acme_server" {
  description = "ACME directory URL used by cert-manager"
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

# Node pool configuration
variable "node_count" {
  description = "Number of worker nodes in the default node pool"
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "VM size for worker nodes"
  type        = string
  default     = "Standard_DC2as_v5"
}

# Network configuration
variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
  default     = "mc-aks-vnet"
}

variable "subnet_name" {
  description = "Name of the subnet for AKS"
  type        = string
  default     = "mc-aks-subnet"
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "multicloud-k8s-failover"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
