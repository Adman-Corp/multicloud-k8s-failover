variable "subscription_id" {
  description = "Azure subscription ID where the main infrastructure will be deployed"
  type        = string
}

variable "service_principal_name" {
  description = "Display name for the Azure AD application and service principal"
  type        = string
  default     = "multicloud-k8s-failover-github-actions"
}

variable "role_definition_name" {
  description = "Azure RBAC role to assign to the service principal at subscription scope"
  type        = string
  default     = "Contributor"
}

variable "password_rotation_days" {
  description = "Number of days before the generated client secret expires"
  type        = number
  default     = 365
}

variable "github_repository" {
  description = "GitHub repository allowed to use Azure OIDC, in owner/repo format"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch allowed to use Azure OIDC"
  type        = string
  default     = "main"
}

variable "tfc_organization" {
  description = "Terraform Cloud organization that owns the deployment workspace"
  type        = string
  default     = "AdmanCorp"
}

variable "tfc_workspace_name" {
  description = "Terraform Cloud workspace name for the main Azure deployment stack"
  type        = string
  default     = "admancorp-azure-aks-prod"
}

variable "tfc_hostname" {
  description = "Terraform Cloud or Terraform Enterprise hostname"
  type        = string
  default     = "app.terraform.io"
}
