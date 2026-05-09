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
  description = "Cluster-specific public hostname routed to Argo CD through Envoy Gateway"
  type        = string
  default     = null
}

variable "platform_gateway_wildcard" {
  description = "Wildcard hostname for the shared platform Gateway TLS listener"
  type        = string
  default     = null
}

variable "envoy_gateway_chart_version" {
  description = "Envoy Gateway Helm chart version"
  type        = string
  default     = "v1.7.2"
}

variable "envoy_gateway_namespace" {
  description = "Namespace where Envoy Gateway is installed"
  type        = string
  default     = "envoy-gateway-system"
}

variable "platform_ingress_namespace" {
  description = "Namespace for shared Gateway and listener resources"
  type        = string
  default     = "platform-ingress"
}

variable "envoy_gateway_dns_hostname" {
  description = "Cluster-specific DNS hostname for the Envoy public load balancer"
  type        = string
  default     = null
}

variable "argocd_certificate_name" {
  description = "cert-manager Certificate name for the Argo CD Gateway listener TLS"
  type        = string
  default     = "argocd-gateway-tls"
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

variable "node_machine_type" {
  description = "Machine type for worker nodes"
  type        = string
  default     = "e2-medium"
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
