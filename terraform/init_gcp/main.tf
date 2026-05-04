locals {
  use_folder = var.folder_id != null && trim(var.folder_id) != ""

  environment_projects = {
    dev = {
      project_id   = var.dev_project_id
      display_name = "${var.project_name} Dev"
    }
    uat = {
      project_id   = var.uat_project_id
      display_name = "${var.project_name} UAT"
    }
    prod = {
      project_id   = var.prod_project_id
      display_name = "${var.project_name} Prod"
    }
  }

  bootstrap_activate_apis = toset([
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "serviceusage.googleapis.com",
  ])

  deployer_roles = toset([
    "roles/container.admin",
    "roles/compute.networkAdmin",
    "roles/iam.serviceAccountUser",
    "roles/serviceusage.serviceUsageAdmin",
  ])
}

resource "google_project" "environment" {
  for_each = local.environment_projects

  project_id      = each.value.project_id
  name            = each.value.display_name
  billing_account = var.billing_account
  org_id          = local.use_folder ? null : var.organization_id
  folder_id       = local.use_folder ? var.folder_id : null

  lifecycle {
    precondition {
      condition     = local.use_folder || (var.organization_id != null && trimspace(var.organization_id) != "")
      error_message = "Set either folder_id or organization_id for the new GCP project."
    }
  }
}

resource "google_project_service" "bootstrap_required" {
  for_each = local.bootstrap_activate_apis

  project            = var.bootstrap_project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_project_service" "required" {
  for_each = {
    for entry in flatten([
      for env_name, config in local.environment_projects : [
        for service in var.activate_apis : {
          key        = "${env_name}:${service}"
          env_name   = env_name
          project_id = config.project_id
          service    = service
        }
      ]
    ]) : entry.key => entry
  }

  project            = each.value.project_id
  service            = each.value.service
  disable_on_destroy = false
}

resource "google_service_account" "terraform_deployer" {
  project      = var.bootstrap_project_id
  account_id   = var.service_account_id
  display_name = "GitHub Terraform Deployer"

  depends_on = [google_project_service.bootstrap_required]
}

resource "google_project_iam_member" "deployer_project_roles" {
  for_each = {
    for entry in flatten([
      for env_name, config in local.environment_projects : [
        for role in local.deployer_roles : {
          key        = "${env_name}:${role}"
          project_id = config.project_id
          role       = role
        }
      ]
    ]) : entry.key => entry
  }

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.terraform_deployer.email}"
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.bootstrap_project_id
  workload_identity_pool_id = var.workload_identity_pool_id
  display_name              = "GitHub Actions Pool"
  description               = "Federates GitHub Actions OIDC identities into GCP"

  depends_on = [google_project_service.bootstrap_required]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.bootstrap_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.workload_identity_provider_id
  display_name                       = "GitHub Repository Provider"
  description                        = "Trusts the GitHub OIDC issuer for a specific repository owner"
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
  }
  attribute_condition = "assertion.repository_owner == '${var.github_repository_owner}'"
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_workload_identity_user" {
  service_account_id = google_service_account.terraform_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

resource "tfe_workspace" "gcp_main" {
  name              = var.tfc_workspace_name
  organization      = var.tfc_organization
  description       = "GKE prod deployment workspace for multicloud-k8s-failover"
  working_directory = "terraform/gcp"
  execution_mode    = "local"
}

resource "tfe_workspace" "gcp_dev" {
  name              = "admancorp-gcp-gke-dev"
  organization      = var.tfc_organization
  description       = "GKE dev deployment workspace for multicloud-k8s-failover"
  working_directory = "terraform/gcp"
  execution_mode    = "local"
}

resource "tfe_workspace" "gcp_uat" {
  name              = "admancorp-gcp-gke-uat"
  organization      = var.tfc_organization
  description       = "GKE uat deployment workspace for multicloud-k8s-failover"
  working_directory = "terraform/gcp"
  execution_mode    = "local"
}
