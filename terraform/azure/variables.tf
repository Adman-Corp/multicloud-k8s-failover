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
  default     = "1.29"
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
  default     = "Standard_B2s"
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