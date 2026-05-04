# Azure Bootstrap Terraform

This stack creates the Azure identity required by the GitHub Actions workflow:

- Azure AD application
- Azure service principal
- Federated identity credential for GitHub OIDC
- Subscription-scope RBAC assignment
- Terraform Cloud workspace for `terraform/azure` with local execution for remote state only

This bootstrap stack also stores its own state in the separate Terraform Cloud workspace `admancorp-azure-init`.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Fill in your Azure subscription ID
3. Run `terraform init -migrate-state` if you are moving from local state
4. Run `terraform apply`

## Outputs

This stack outputs the generated Azure service principal values for use in GitHub Actions secrets or variables.

Use these outputs to populate:

- `ARM_CLIENT_ID`
- `ARM_TENANT_ID`
- `ARM_SUBSCRIPTION_ID`

You still need an existing Azure subscription. This stack does not create subscriptions.
You must authenticate the `tfe` provider with `TFE_TOKEN` before applying this bootstrap stack.
