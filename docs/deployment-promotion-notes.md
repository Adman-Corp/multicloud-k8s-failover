# Deployment Promotion Notes

## Current State

- Pushes to `main` automatically deploy Terraform to `dev`.
- Pull requests run `fmt`, `init`, `validate`, and `plan` for `dev`, `uat`, and `prod` and publish a summary comment with an artifact link.

## Follow-Up Work

- Define what counts as a successful `dev` deployment beyond `terraform apply` succeeding.
- Add post-deploy verification for `dev`:
  - infrastructure health checks
  - smoke tests
  - basic observability checks
- Define promotion rules so only verified `dev` revisions can move to `uat`.
- Add protected GitHub environments for `uat` and `prod`.
- Define production promotion from immutable tags instead of long-lived environment branches.

## Target Promotion Model

- `main` deploys automatically to `dev`
- `uat` is promoted from a verified revision
- `prod` is promoted from a tagged verified revision
- all promotions use the same Git commit SHA to avoid environment drift
