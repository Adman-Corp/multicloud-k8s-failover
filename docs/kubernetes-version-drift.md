# Kubernetes Version Drift

## Issue

AKS and GKE can drift to different Kubernetes versions even when the repository appears to request the same target version.

This matters for a multi-cloud failover setup because failover confidence depends on both clusters behaving as similarly as possible.

## What Happened Here

- Azure was configured to use Kubernetes `1.34`.
- GCP tfvars also declared `1.34`.
- GKE still deployed as `1.35.3-gke.1234000`.

The main reason was that the GKE stack defined a `kubernetes_version` variable but did not actually enforce that version on the cluster and node pool resources.

The GKE stack also used a release channel and node auto-upgrade behavior, which allowed Google to choose a newer supported version.

## Why This Happens

- Managed Kubernetes providers may select versions automatically when the version is not fully pinned.
- Managed Kubernetes providers may auto-upgrade clusters or node pools.
- AKS and GKE do not expose version strings in the same format.
- Providers can roll forward on their own schedules.
- Older versions may eventually be deprecated and force upgrades.

## What Parity Should Mean

For this repository, parity should usually mean:

- the same Kubernetes minor version on AKS and GKE
- patch/build differences are acceptable if they come from provider packaging

Examples:

- good parity: AKS `1.34.x`, GKE `1.34.x-gke.*`
- drift: AKS `1.34.x`, GKE `1.35.x-gke.*`

Exact version string equality across providers is not realistic.
Minor version parity is the important control point.

## Risks Of Version Drift

- Kubernetes APIs may behave differently across clouds.
- Add-ons and manifests may work in one cluster and fail in the other.
- Failover tests become less meaningful.
- Production incidents become harder to reason about because the two clusters are no longer equivalent.

## Recommended Controls

### 1. Use One Shared Kubernetes Version Source

Keep one canonical Kubernetes version value for both cloud stacks.

Examples:

- a shared tfvars file consumed by both stacks
- a shared Terraform variable source used by CI
- generated environment tfvars derived from one version definition

This should be the source of truth for the desired Kubernetes minor version.

### 2. Pin Versions Explicitly In Both Providers

Do not rely on a variable existing in code unless it is actually wired into the managed cluster resources.

AKS should explicitly set the cluster and relevant node pool version fields.

GKE should explicitly set the cluster and node pool version fields when version parity is required.

### 3. Avoid Floating Version Selection When Parity Matters

If release channels or provider defaults are allowed to choose versions automatically, AKS and GKE can drift.

If strict parity is required:

- avoid floating version selection
- avoid relying on release channel behavior alone
- review auto-upgrade settings carefully

### 4. Add Drift Detection

Run a scheduled check that compares:

- desired version in code
- actual AKS version
- actual GKE version

The check should alert or fail when:

- AKS and GKE minor versions differ
- actual version differs from configured target unexpectedly
- one provider has advanced while the other has not

### 5. Upgrade Intentionally

When moving from one Kubernetes minor version to another:

- update the shared version source once
- roll both cloud stacks in the same change set or same promotion cycle
- verify workloads and add-ons in both clouds

This reduces hidden divergence over time.

## Operational Reality

Even with explicit pinning, cloud providers may eventually force upgrades when versions become unsupported.

That cannot be prevented forever.

What can be controlled:

- how long the cluster stays pinned
- how quickly drift is detected
- whether upgrades happen intentionally or as a surprise
- whether both providers are moved together

## Practical Repo Direction

For this repository, the most practical long-term approach is:

- define one shared Kubernetes target version
- make both `terraform/azure` and `terraform/gcp` consume it explicitly
- remove any accidental floating-version behavior from GKE if parity is required
- add scheduled CI drift checks for actual AKS and GKE versions
- treat Kubernetes minor upgrades as coordinated cross-cloud changes

## Possible Solutions Summary

### Minimal Solution

- keep version values aligned manually in both stacks
- pin the version fields correctly

This is better than the current behavior but still depends on discipline.

### Better Solution

- introduce a single shared version source
- pin AKS and GKE to it
- add CI validation that both stacks match

This reduces configuration drift inside the repository.

### Best Operational Solution

- introduce a single shared version source
- pin both stacks to it
- add scheduled drift detection against live clusters
- review provider deprecation windows regularly
- upgrade both clouds in one controlled process

This gives the best balance of parity, predictability, and operational visibility.
