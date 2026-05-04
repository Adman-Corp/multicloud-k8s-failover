# Azure AKS Terraform Module

This directory contains Terraform configuration to provision an AKS cluster on Azure for the multi-cloud Kubernetes active-passive disaster recovery project.

## Prerequisites

- Azure subscription
- Service principal with Contributor role (or appropriate permissions)
- Terraform 1.0+ installed

## Authentication

Set environment variables:
```bash
export ARM_CLIENT_ID="<service-principal-app-id>"
export ARM_CLIENT_SECRET="<service-principal-password>"
export ARM_TENANT_ID="<azure-tenant-id>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
```

Alternatively, use Azure CLI (`az login`).

## Remote State Backend

The configuration uses Terraform Cloud for remote state management. The `terraform` block in `provider.tf` is already configured with:

```hcl
cloud {
  organization = "AdmanCorp"

  workspaces {
    name = "admancorp-github-iac"
  }
}
```

To use Terraform Cloud:

1. Ensure you're logged into Terraform Cloud CLI (`terraform login`)
2. Run `terraform init` to initialize with Terraform Cloud backend
3. Terraform will automatically use the remote workspace for state storage

For local development, you can switch to local backend by commenting out the `cloud` block and using `backend "local"`.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values.
2. Run `terraform init`.
3. Run `terraform plan` to review changes.
4. Run `terraform apply` to provision infrastructure.

## Variables

See `variables.tf` for configurable options.

## Outputs

After applying, outputs include:
- `cluster_endpoint`: Kubernetes API endpoint
- `kubeconfig`: Kubeconfig YAML (sensitive)
- `cluster_name`
- `resource_group_name`
- `oidc_issuer_url` for External Secrets

## Cleanup

Run `terraform destroy` to remove all resources.