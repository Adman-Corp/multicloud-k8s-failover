# GCP GKE Terraform Module

This directory contains Terraform configuration to provision a GKE cluster on Google Cloud Platform for the multi-cloud Kubernetes active-passive disaster recovery project.

## Prerequisites

- GCP project with billing enabled
- Service account with appropriate permissions (Kubernetes Engine Admin, Compute Network Admin, etc.)
- Terraform 1.0+ installed

## Authentication

Set environment variable:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account-key.json"
```

Alternatively, use `gcloud auth application-default login`.

## Remote State Backend

The configuration uses Google Cloud Storage (GCS) for remote state. To enable:

1. Create a GCS bucket in your project.
2. Uncomment the `backend "gcs"` block in `provider.tf`.
3. Create `backend.tfvars` with values:

```hcl
bucket = "tfstate-multicloud-gke"
prefix = "terraform/state"
```

4. Run `terraform init -backend-config=backend.tfvars`.

For local development, the local backend is configured by default.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values (especially `project_id`).
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
- `workload_identity_pool` for External Secrets

## Cleanup

Run `terraform destroy` to remove all resources.