output "environment_project_ids" {
  description = "Created GCP project IDs by environment"
  value = {
    for env_name, project in google_project.environment : env_name => project.project_id
  }
}

output "environment_project_numbers" {
  description = "Created GCP project numbers by environment"
  value = {
    for env_name, project in google_project.environment : env_name => project.number
  }
}

output "identity_project_id" {
  description = "Bootstrap GCP project that hosts the GitHub OIDC pool and Terraform deployer service account"
  value       = var.bootstrap_project_id
}

output "terraform_service_account_email" {
  description = "Service account email for GitHub Actions Terraform deployments"
  value       = google_service_account.terraform_deployer.email
}

output "workload_identity_provider_name" {
  description = "Full Workload Identity Provider resource name for GitHub Actions"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "workload_identity_provider_id" {
  description = "GitHub Actions workload identity provider ID"
  value       = google_iam_workload_identity_pool_provider.github.workload_identity_pool_provider_id
}

output "tfc_workspace_name" {
  description = "Terraform Cloud workspace name for the GCP deployment stack"
  value       = tfe_workspace.gcp_main.name
}
