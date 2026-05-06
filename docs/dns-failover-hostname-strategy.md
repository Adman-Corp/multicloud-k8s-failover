# DNS Failover Hostname Strategy

## Purpose

This document explains the DNS ownership issue that appears when the same
application hostname must move between Azure AKS and GCP GKE, the solutions that
were considered, and the solution selected for this repository.

The main example in this document uses:

- public application hostname: `app.admancorp.com`
- Azure Argo CD hostname: `argocd.az.admancorp.com`
- GCP Argo CD hostname: `argocd.gcp.admancorp.com`

## Context

The target platform design is:

- `Envoy Gateway` runs in both clusters
- Argo CD runs in both clusters
- normal applications run in only one cluster at a time
- the public application hostname should stay stable during failover
- Argo CD remains the operational exception and keeps cluster-specific hostnames

The intended application failover flow is:

1. the application normally runs in Azure
2. if failover is needed, the application is removed from Azure
3. the application is deployed in GCP
4. the public hostname should point to the GCP cluster instead of Azure

## Current external-dns Behavior In This Repository

The current Terraform bootstrap config uses `external-dns` with:

- `policy = upsert-only`
- `registry = txt`
- cluster-specific `txtOwnerId`

This is good for safe record management in a single cluster, but it is a poor
fit for handing the same public hostname back and forth between two clusters.

## Problem

If both clusters may publish the same hostname, such as `app.admancorp.com`, DNS
ownership becomes ambiguous.

With the current `external-dns` settings, the failover sequence is fragile:

1. Azure currently serves `app.admancorp.com`
2. Azure application is removed
3. GCP application is deployed
4. GCP `external-dns` tries to publish the same hostname

The problems are:

- `upsert-only` does not clean up the old record during handoff
- cluster-specific `txtOwnerId` values make same-name ownership transfer awkward
- two clusters can contend for the same DNS name over time
- failover timing becomes dependent on controller reconciliation behavior instead
  of an explicit traffic switch

This makes the public app hostname harder to reason about during failover.

## Solutions Considered

### Option 1: Let external-dns Manage The Shared Public Hostname Directly

Example:

- Azure chart publishes `app.admancorp.com`
- later GCP chart publishes `app.admancorp.com`

Advantages:

- the hostname stays fully chart-driven
- the public hostname is declared directly in the app route/manifest

Disadvantages:

- record handoff between clusters is brittle
- deletion and creation timing matters during failover
- current `upsert-only` behavior is a bad fit
- TXT ownership transfer is more complex
- DNS state changes are driven indirectly by controller behavior instead of one
  explicit failover action

This option is possible, but it is operationally weaker.

### Option 2: Use Cluster-Specific Target Records And A Shared Public Alias

Example:

- `app.admancorp.com` remains the public hostname
- `azure-gw.admancorp.com` points to the Azure Envoy load balancer
- `gcp-gw.admancorp.com` points to the GCP Envoy load balancer
- Cloudflare flips `app.admancorp.com` to the active target

Advantages:

- one explicit DNS switch during failover
- no shared-record contention between clusters
- `external-dns` can continue using `upsert-only`
- `external-dns` remains useful for cluster-local record management
- the public app hostname remains stable for users

Disadvantages:

- the final public alias is not owned directly by the application chart
- failover automation must update one Cloudflare record

This option is operationally safer and simpler.

## Proposed Solution

Use split DNS ownership.

### external-dns Owns Cluster-Specific Records

`external-dns` should manage only records that belong to one cluster, such as:

- `argocd.az.admancorp.com`
- `argocd.gcp.admancorp.com`
- `azure-gw.admancorp.com`
- `gcp-gw.admancorp.com`

These records map to the local Envoy Gateway `LoadBalancer` service in each
cluster.

### Failover Automation Owns Shared App Hostnames

Failover automation should manage only the shared public application hostnames,
such as:

- `app.admancorp.com`

That record should point to the currently active cluster-specific target, for
example:

- normal state: `app.admancorp.com -> azure-gw.admancorp.com`
- failover state: `app.admancorp.com -> gcp-gw.admancorp.com`

## Taken Decision

The selected solution is Option 2.

This means:

- the public app hostname stays stable
- the final public app DNS switch is handled by failover automation
- `external-dns` keeps managing cluster-specific records only
- Argo CD keeps cluster-specific hostnames and is not part of the shared app
  failover record

## Important Clarification

This does not require removing the app hostname from the chart.

The application chart can still declare:

- `app.admancorp.com` in the `HTTPRoute`

What moves outside the chart is only the DNS ownership of the final public
record and, when wildcard listener certificates are used, the TLS certificate
ownership as well.

In other words:

- the chart still knows the public hostname
- the cluster still serves that hostname when active
- only the Cloudflare alias switch is controlled externally
- the platform layer may also own the wildcard listener certificate that covers
  the hostname

DNS ownership is only one part of the failover design. The active cluster also
needs to be controlled by one failover authority, and the old active cluster
must be fenced so both clusters do not behave as production-active at the same
time. The detailed authority and fencing model is described in
`docs/envoy-gateway-architecture.md`.

## Recommended Flow

### Normal State

1. Azure hosts the application
2. Azure Envoy Gateway serves `app.admancorp.com`
3. `external-dns` maintains `azure-gw.admancorp.com`
4. Cloudflare points `app.admancorp.com` to `azure-gw.admancorp.com`

### Failover State

1. the application is deployed and verified healthy in GCP
2. GCP Envoy Gateway serves `app.admancorp.com`
3. `external-dns` maintains `gcp-gw.admancorp.com`
4. failover automation updates Cloudflare:
   `app.admancorp.com -> gcp-gw.admancorp.com`
5. Azure application can then be disabled or removed if desired

This makes the public cutover explicit and predictable.

## Why This Solution Was Chosen

- safer than relying on `external-dns` ownership transfer for the same hostname
- compatible with the current `upsert-only` and TXT registry setup
- preserves a stable application hostname for users
- keeps Argo CD independently reachable on both clusters
- keeps application hostname definitions inside the app routing config
- reduces the chance of DNS race conditions during failover

## Consequences

### Positive

- simpler failover operation
- clearer DNS ownership model
- less coupling between failover timing and controller reconciliation
- easier troubleshooting

### Negative

- one extra layer of DNS indirection
- one Cloudflare record must be managed by the failover process

## Summary

The repository will use:

- `external-dns` for cluster-specific DNS records
- failover automation for shared public app hostnames
- cluster-specific Argo CD hostnames
- a stable public application hostname such as `app.admancorp.com`

This keeps the user-facing hostname stable while avoiding cross-cluster DNS
ownership conflicts.
