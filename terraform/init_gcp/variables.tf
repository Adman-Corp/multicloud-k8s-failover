variable "bootstrap_project_id" {
  description = "Existing GCP project ID used to authenticate and bootstrap the new project"
  type        = string
}

variable "dev_project_id" {
  description = "Project ID for the GKE dev environment"
  type        = string
}

variable "uat_project_id" {
  description = "Project ID for the GKE uat environment"
  type        = string
}

variable "prod_project_id" {
  description = "Project ID for the GKE prod environment"
  type        = string
}

variable "project_name" {
  description = "Display name prefix for the GCP environment projects"
  type        = string
  default     = "Multi-Cloud K8s Failover"
}

variable "organization_id" {
  description = "GCP organization ID. Leave null if using a folder instead"
  type        = string
  default     = null
}

variable "folder_id" {
  description = "GCP folder ID. Leave null if creating the project directly under the organization"
  type        = string
  default     = null
}

variable "billing_account" {
  description = "Billing account ID to link to the new project"
  type        = string
}

variable "region" {
  description = "Default region for bootstrap resources"
  type        = string
  default     = "us-central1"
}

variable "service_account_id" {
  description = "Account ID for the Terraform deployer service account"
  type        = string
  default     = "github-terraform"
}

variable "github_repository" {
  description = "GitHub repository allowed to impersonate the GCP deployer service account, in owner/repo format"
  type        = string
}

variable "github_repository_owner" {
  description = "GitHub organization or user that owns the repository"
  type        = string
}

variable "workload_identity_pool_id" {
  description = "Workload Identity Pool ID for GitHub federation"
  type        = string
  default     = "github"
}

variable "workload_identity_provider_id" {
  description = "Workload Identity Provider ID for GitHub federation"
  type        = string
  default     = "github-repo"
}

variable "tfc_organization" {
  description = "Terraform Cloud organization that owns the deployment workspace"
  type        = string
  default     = "AdmanCorp"
}

variable "tfc_workspace_name" {
  description = "Terraform Cloud workspace name for the main GCP deployment stack"
  type        = string
  default     = "admancorp-gcp-gke-prod"
}

variable "tfc_hostname" {
  description = "Terraform Cloud or Terraform Enterprise hostname"
  type        = string
  default     = "app.terraform.io"
}

variable "activate_apis" {
  description = "GCP APIs required by the main GKE stack"
  type        = set(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iamcredentials.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com"
  ]
}
