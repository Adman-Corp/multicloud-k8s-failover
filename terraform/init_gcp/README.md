# GCP Bootstrap Terraform

This stack creates the GCP prerequisites required by the main GKE Terraform stack and the GitHub Actions workflow:

- Dedicated GCP projects for `dev`, `uat`, and `prod`
- Required GCP APIs in each environment project
- A shared Terraform deployer service account in the bootstrap project
- Basic IAM roles for GKE and networking in each environment project
- Workload Identity Pool and Provider for GitHub Actions OIDC in the bootstrap project
- IAM binding allowing the configured GitHub repository to impersonate the shared deployer service account
- Terraform Cloud workspace for `terraform/gcp` with local execution for remote state only

This bootstrap stack also stores its own state in the separate Terraform Cloud workspace `admancorp-gcp-init`.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Fill in your bootstrap project, billing account, and organization or folder target
3. Run `terraform init -migrate-state` if you are moving from local state
4. Run `terraform apply`

## Outputs

This stack outputs the created environment project IDs, the shared deployer service account email, and the Workload Identity Provider name for use in GitHub Actions variables.

Use these outputs to populate:

- `GCP_SERVICE_ACCOUNT_EMAIL`
- `GCP_WORKLOAD_IDENTITY_PROVIDER`

The existing `bootstrap_project_id` hosts the shared GitHub OIDC pool and deployer service account. That shared identity is granted access to the separate `dev`, `uat`, and `prod` projects.

You need permissions in the bootstrap project plus the ability to create projects under the chosen organization or folder.
You must authenticate the `tfe` provider with `TFE_TOKEN` before applying this bootstrap stack.
