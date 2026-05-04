# GCP project ID
variable "project_id" {
  description = "GCP project ID where resources will be deployed"
  type        = string
}

# Region and zone
variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for zonal cluster"
  type        = string
  default     = "us-central1-a"
}

# Cluster name
variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "mc-gke"
}

# Kubernetes version
variable "kubernetes_version" {
  description = "Kubernetes version for the GKE cluster"
  type        = string
  default     = "1.34"
}

# Node pool configuration
variable "node_count" {
  description = "Number of worker nodes in the default node pool"
  type        = number
  default     = 1
}

variable "node_machine_type" {
  description = "Machine type for worker nodes"
  type        = string
  default     = "e2-small"
}

variable "node_disk_size_gb" {
  description = "Disk size for worker nodes (GB)"
  type        = number
  default     = 30
}

# Network configuration
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "mc-gke-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet for GKE"
  type        = string
  default     = "mc-gke-subnet"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.1.1.0/24"
}

# Workload Identity
variable "workload_identity_enabled" {
  description = "Enable Workload Identity for External Secrets"
  type        = bool
  default     = true
}

# Tags
variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default = {
    project     = "multicloud-k8s-failover"
    environment = "prod"
    managed-by  = "terraform"
  }
}
