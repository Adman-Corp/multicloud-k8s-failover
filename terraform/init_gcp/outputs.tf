output "project_id" {
  description = "Created GCP project ID"
  value       = google_project.main.project_id
}

output "project_number" {
  description = "Created GCP project number"
  value       = google_project.main.number
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
