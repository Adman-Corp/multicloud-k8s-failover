data "azurerm_client_config" "current" {}

resource "azuread_application" "github_actions" {
  display_name = var.service_principal_name
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

resource "time_rotating" "password_expiry" {
  rotation_days = var.password_rotation_days
}

resource "azuread_application_password" "github_actions" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-terraform"
  end_date       = time_rotating.password_expiry.rotation_rfc3339
}

resource "azuread_application_federated_identity_credential" "github_actions" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-oidc"
  description    = "Allows GitHub Actions to authenticate to Azure using OIDC"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"
}

resource "azuread_application_federated_identity_credential" "github_actions_pull_request" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-oidc-pull-request"
  description    = "Allows GitHub Actions pull request workflows to authenticate to Azure using OIDC"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repository}:pull_request"
}

resource "azurerm_role_assignment" "github_actions_subscription" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = var.role_definition_name
  principal_id         = azuread_service_principal.github_actions.object_id
}

resource "tfe_workspace" "azure_main" {
  name              = var.tfc_workspace_name
  organization      = var.tfc_organization
  description       = "AKS deployment workspace for multicloud-k8s-failover"
  working_directory = "terraform/azure"
  execution_mode    = "local"
}

resource "tfe_workspace" "azure_dev" {
  name              = "admancorp-azure-aks-dev"
  organization      = var.tfc_organization
  description       = "AKS dev deployment workspace for multicloud-k8s-failover"
  working_directory = "terraform/azure"
  execution_mode    = "local"
}

resource "tfe_workspace" "azure_uat" {
  name              = "admancorp-azure-aks-uat"
  organization      = var.tfc_organization
  description       = "AKS uat deployment workspace for multicloud-k8s-failover"
  working_directory = "terraform/azure"
  execution_mode    = "local"
}
