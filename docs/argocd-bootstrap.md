# Argo CD Bootstrap

## Purpose

This repository now includes a minimal Argo CD bootstrap for both dev clusters:

- Azure AKS dev
- GCP GKE dev

Terraform installs the cluster bootstrap components before GitOps takes over.
For the dev clusters this now includes `external-dns`, `cert-manager`, and
`Envoy Gateway` before Argo CD in the `argocd` namespace. `cert-manager` is
bootstrapped with a Cloudflare-backed DNS-01 `ClusterIssuer` for Let's
Encrypt. Argo CD is exposed through the shared Envoy `Gateway` rather than its
own public `LoadBalancer` service. In this repository, that shared Gateway is
currently used for platform access such as Argo CD, not application routing.

## Repository Layout

- `gitops/bootstrap/argocd/base`: base Argo CD installation
- `gitops/bootstrap/argocd/overlays/azure-dev`: AKS dev overlay
- `gitops/bootstrap/argocd/overlays/gcp-dev`: GKE dev overlay
- `gitops/clusters/azure-dev/root-application.yaml`: AKS dev root app
- `gitops/clusters/gcp-dev/root-application.yaml`: GKE dev root app
- `gitops/platform/base`: shared Argo CD project definitions
- `gitops/platform/azure/dev`: Azure dev platform app tree
- `gitops/platform/gcp/dev`: GCP dev platform app tree

## Bootstrap Flow

1. Apply the Terraform stack for the target cluster.
2. Terraform installs any bootstrap operators required before Argo CD.
3. Terraform installs the Argo CD Helm release into `argocd`.
4. Apply the cluster root `Application` manifest.
5. Let Argo CD manage the platform app tree from this repository.

## Azure Dev

After Terraform has applied successfully, apply the root application:

```bash
kubectl apply -f gitops/clusters/azure-dev/root-application.yaml
```

Azure dev also bootstraps `external-dns`, `cert-manager`, and `Envoy Gateway`
before Argo CD. The shared Envoy public service is annotated so
`external-dns` can publish both `azure-gw.admancorp.com` and
`argocd.az.admancorp.com`.

## GCP Dev

After Terraform has applied successfully, apply the root application:

```bash
kubectl apply -f gitops/clusters/gcp-dev/root-application.yaml
```

GCP dev also bootstraps `external-dns`, `cert-manager`, and `Envoy Gateway`
before Argo CD. The shared Envoy public service is annotated so
`external-dns` can publish both `gcp-gw.admancorp.com` and
`argocd.gcp.admancorp.com`.

## Initial Admin Password

After Argo CD is installed, retrieve the initial admin password with:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## Current Scope

The current root applications establish the shared `platform` project and the
initial Envoy-based ingress resources under:

- `gitops/platform/azure/dev`
- `gitops/platform/gcp/dev`
