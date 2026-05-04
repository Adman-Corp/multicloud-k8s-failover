output "client_id" {
  description = "Client ID for the generated Azure service principal"
  value       = azuread_application.github_actions.client_id
}

output "client_secret" {
  description = "Client secret for the generated Azure service principal"
  value       = azuread_application_password.github_actions.value
  sensitive   = true
}

output "federated_identity_subject" {
  description = "GitHub OIDC subject trusted by Azure"
  value       = azuread_application_federated_identity_credential.github_actions.subject
}

output "tenant_id" {
  description = "Azure tenant ID used for authentication"
  value       = data.azurerm_client_config.current.tenant_id
}

output "subscription_id" {
  description = "Azure subscription ID used for deployment"
  value       = var.subscription_id
}

output "service_principal_object_id" {
  description = "Object ID of the generated Azure service principal"
  value       = azuread_service_principal.github_actions.object_id
}

output "tfc_workspace_name" {
  description = "Terraform Cloud workspace name for the Azure deployment stack"
  value       = tfe_workspace.azure_main.name
}
