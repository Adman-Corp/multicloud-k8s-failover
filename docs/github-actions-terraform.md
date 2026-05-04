# GitHub Actions Terraform Deployment

This repository includes a GitHub Actions workflow at `.github/workflows/terraform-deploy.yml` that runs Terraform for both cloud stacks:

- `terraform/azure`
- `terraform/gcp`

## Workflow Behavior

- Pull requests: run `terraform fmt -check`, then run `terraform init`, `terraform validate`, and `terraform plan` separately for `dev`, `uat`, and `prod`
- Pushes to `main`: run the same checks and then `terraform apply`
- Manual runs: choose `dev`, `uat`, or `prod`, choose `azure`, `gcp`, or `all`, and choose `plan` or `apply`

For pull requests, the workflow runs `init`, `validate`, and `plan` for `dev`, `uat`, and `prod`, posts add/change/delete counts as a PR comment, and uploads the full outputs as a workflow artifact.

## Required GitHub Secrets

Create these repository or environment secrets:

- `TF_API_TOKEN`: Terraform Cloud user or team token

- `ARM_CLIENT_ID`
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`

## Required GitHub Variables

Set these repository or environment variables:

- `GCP_SERVICE_ACCOUNT_EMAIL`
- `GCP_WORKLOAD_IDENTITY_PROVIDER`

## Recommended Defaults

Environment-specific Terraform values are now stored in committed files:

- `terraform/azure/environments/dev.tfvars`
- `terraform/azure/environments/uat.tfvars`
- `terraform/azure/environments/prod.tfvars`
- `terraform/gcp/environments/dev.tfvars`
- `terraform/gcp/environments/uat.tfvars`
- `terraform/gcp/environments/prod.tfvars`

The workflow selects one of those files with `-var-file`.

## Notes

- The workflow relies on the Terraform Cloud backends already configured in `terraform/azure/provider.tf` and `terraform/gcp/provider.tf`.
- Each cloud stack uses environment-specific Terraform Cloud workspaces through a workspace prefix and `TF_WORKSPACE` selection in the workflow.
- The bootstrap stacks should create local-execution workspaces for `dev`, `uat`, and `prod` in both clouds so PR plans do not share state.
- The bootstrap stacks create Terraform Cloud workspaces in local execution mode so Terraform Cloud stores state only.
- The Azure workflow now authenticates through GitHub OIDC and an Azure federated identity credential instead of a stored client secret.
- Azure OIDC must trust both the main branch subject (`repo:<owner>/<repo>:ref:refs/heads/main`) and the pull request subject (`repo:<owner>/<repo>:pull_request`) if PR plans should run against Azure.
- The GCP workflow now authenticates through GitHub OIDC and Google Workload Identity Federation instead of a stored service account key.
- The workflow uses committed environment tfvars files instead of GitHub variables for infrastructure values.
- Pull request comments summarize each environment with add/change/delete counts only, while the `terraform-plan-<stack>` artifact keeps the full init/validate/plan logs.
- The default workspace names created by the bootstrap stacks must stay aligned with the `cloud.workspaces.name` values in the main stack `provider.tf` files.
- If you want approval gates before apply, attach the workflow to a protected GitHub environment and require reviewers there.
