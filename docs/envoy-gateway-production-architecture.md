# Envoy Gateway Production Architecture

## Purpose

This document defines a production target architecture for exposing platform and
application traffic through `Envoy Gateway` across both clusters in this
repository:

- Azure AKS
- GCP GKE

It is intended to answer the practical production design question that follows
the base architecture documents:

- which public load balancers should be used
- how to keep cost reasonable
- which controls are required for a production baseline
- which upgrades are optional rather than mandatory in the first version

This document builds on:

- `docs/envoy-gateway-architecture.md`
- `docs/dns-failover-hostname-strategy.md`

## Executive Summary

The recommended production design is:

- keep `Envoy Gateway` as the only cluster ingress and routing layer
- use one public cloud-native Layer 4 load balancer per cluster in front of
  Envoy
- use `Cloudflare DNS` for cluster-specific and failover-related DNS records
- keep shared application failover DNS owned by failover automation
- do not add Azure Application Gateway or GCP Application Load Balancer in the
  first production version

Recommended public entrypoints:

- AKS: Azure `Standard Load Balancer`
- GKE: GCP external `Network Load Balancer`

This gives the project:

- one symmetric ingress model across both clouds
- lower cost than stacking managed Layer 7 ingress products in front of Envoy
- a simpler operational model for GitOps and failover
- a clean path to later add edge security features if needed

## Design Principles

- Keep one ingress architecture across both clouds
- Pay for one public entrypoint per cluster, not one per application
- Let `Envoy Gateway` do the Layer 7 work
- Keep failover explicit and DNS-driven in the first version
- Add higher-cost edge features only when there is a clear requirement

## Recommended Production Baseline

### Public Traffic Entry

Use one public `Service` of type `LoadBalancer` for the Envoy data plane in each
cluster.

That means:

- AKS creates one Azure public `Standard Load Balancer` frontend for Envoy
- GKE creates one external public `Network Load Balancer` frontend for Envoy
- Envoy listens on ports `80` and `443`
- all public application and Argo CD traffic enters through that one shared
  Envoy entrypoint in each cluster

This is the lowest-cost production approach that still preserves a clear and
reliable architecture.

### Why Layer 4 Load Balancers Are Recommended

`Envoy Gateway` is already the project's Layer 7 ingress component.

It is responsible for:

- TLS termination
- hostname and listener routing
- Gateway API policy enforcement
- routing to Argo CD and application services

Because Envoy already owns those responsibilities, placing a second managed
Layer 7 ingress product in front of it usually adds:

- extra cost
- extra operational complexity
- cloud-specific behavior differences
- another failure domain to troubleshoot

For this design, the public cloud load balancer should be treated mainly as the
network entrypoint that forwards traffic to Envoy.

### What Not To Use In The First Production Version

Do not use these as the default design:

- Azure `Application Gateway`
- GCP `Application Load Balancer`
- one public `LoadBalancer` service per application
- one separate public `LoadBalancer` service for Argo CD
- `Cloudflare Load Balancer` as the primary failover mechanism

These options can be valid for specific requirements, but they are not the best
default choice for a cost-aware, multi-cloud, Envoy-centered architecture.

## Network Architecture

### Baseline Traffic Flow

The recommended production traffic path is:

`User -> Cloudflare -> public cloud load balancer -> Envoy Gateway -> Gateway listeners -> HTTPRoute -> Service`

Per cluster:

- the cloud load balancer provides the public IP address
- the Envoy data plane receives traffic from that load balancer
- the shared `Gateway` terminates TLS and accepts listeners
- `HTTPRoute` resources route traffic to Argo CD or application services

### DNS Model

The DNS ownership model from the existing design remains unchanged.

Cluster-specific records are owned by `external-dns`, for example:

- `azure-gw.admancorp.com`
- `gcp-gw.admancorp.com`
- `argocd.az.admancorp.com`
- `argocd.gcp.admancorp.com`

Shared application hostnames are owned by failover automation, for example:

- `app.admancorp.com`

That shared application record points to the currently active cluster-specific
gateway record:

- normal state: `app.admancorp.com -> azure-gw.admancorp.com`
- failover state: `app.admancorp.com -> gcp-gw.admancorp.com`

## Production Tiers

### Tier 1: Cost-Aware Production Baseline

This is the recommended first production version.

Use:

- `Cloudflare DNS` only
- AKS `Standard Load Balancer`
- GKE external `Network Load Balancer`
- `Envoy Gateway` in both clusters
- manual or pipeline-driven failover automation
- low DNS TTL for shared app hostnames
- pre-provisioned TLS certificates in both clusters

Benefits:

- lowest cost among the practical production options
- symmetric architecture across clouds
- simple troubleshooting path
- no dependency on cloud-specific Layer 7 ingress products

Tradeoffs:

- failover time depends partly on DNS propagation and client caching
- in-flight connections may break during cutover
- edge security controls are limited to what Cloudflare DNS and Envoy provide

### Tier 2: Production With Stronger Edge Security

Use this when there is a clear requirement for edge protection such as WAF, bot
management, or enhanced DDoS controls.

Use:

- the same cluster architecture as Tier 1
- `Cloudflare` proxy features in front of the cluster origins
- optional Cloudflare WAF and security controls

Keep these unchanged:

- one public cloud load balancer per cluster
- Envoy remains the origin ingress layer
- Envoy remains the Gateway API controller and router

Benefits:

- stronger internet edge protection
- centralized security policy at the edge
- preserves the same in-cluster ingress model

Tradeoffs:

- higher platform cost than DNS-only Cloudflare usage
- more coupling to Cloudflare-specific edge features

### Tier 3: Production With Faster And More Automated Failover

Use this when operational requirements demand less manual intervention and more
reliable cutover workflows.

Add:

- standby workload pre-deployment in the passive cluster
- promotion automation with health and readiness checks
- automated DNS update for shared application hostnames
- automated public smoke tests after cutover
- rollback or operator-stop behavior if smoke tests fail

Benefits:

- lower failover operational burden
- less manual error risk during incidents
- better consistency of failover execution

Tradeoffs:

- more automation to build and maintain
- still bounded by DNS failover behavior unless a different global traffic layer
  is introduced later

## Production Controls Required In All Tiers

### Envoy Availability

Each cluster should run the Envoy data plane in a highly available way.

Recommended minimum controls:

- at least 2 replicas, preferably 3 when zone count and scale justify it
- spread replicas across zones when the cluster is multi-zone
- `PodDisruptionBudget` for Envoy pods
- topology spread constraints or anti-affinity
- sufficient CPU and memory requests and limits based on measured traffic

### Gateway And Routing Stability

- one shared public `Gateway` per cluster
- explicit listener definitions for Argo CD and public application hostnames
- application `HTTPRoute` resources attached only through approved route policy
- no direct public exposure of application services outside Envoy

### TLS Readiness

- use `cert-manager` with the existing Cloudflare-backed DNS-01 issuer
- provision listener certificates independently in both clusters
- ensure the passive cluster already has valid TLS material before promotion
- do not depend on certificate issuance during an incident

### Failover Controls

- one clear failover authority
- one recorded active-cluster value
- one explicit promotion workflow
- one fencing step for the old active cluster
- one post-cutover smoke test against the shared public hostname

### Observability

At minimum, production should include:

- Envoy access logs
- Envoy metrics suitable for request rate, latency, and response code tracking
- monitoring for public endpoint availability
- health checks for:
  - `argocd.az.admancorp.com`
  - `argocd.gcp.admancorp.com`
  - `app.admancorp.com`

## Cost Guidance

### Lowest-Cost Sensible Production Model

The lowest-cost sensible production design for this repository is:

- one public load balancer per cluster
- one shared Envoy ingress per cluster
- no per-application public load balancers
- no cloud-managed Layer 7 ingress in front of Envoy
- Cloudflare DNS rather than Cloudflare Load Balancer

This approach controls cost because it avoids paying multiple times for:

- public IP and load balancer resources per app
- provider-specific Layer 7 ingress services
- duplicate TLS and routing layers

### Main Cost Drivers To Watch

- public load balancer hourly cost and data processing
- cross-zone traffic inside each cluster
- internet egress from each cloud
- Cloudflare plan level if proxy and WAF features are enabled
- standby environment size if the passive cluster keeps workloads warm

### False Economies To Avoid

These can appear cheaper in isolation but often increase operational risk or
complexity:

- directly exposing many services through separate public load balancers
- making Argo CD a separate public ingress path from applications
- mixing multiple ingress stacks for the same traffic class
- introducing cloud-native Layer 7 ingress products just for familiarity

## When To Upgrade Beyond The Baseline

Stay on the baseline design unless one of these becomes a real requirement:

- enterprise WAF or bot management
- edge caching or CDN behavior
- global traffic steering by geography or policy
- failover expectations that DNS alone cannot satisfy
- compliance requirements for provider-specific edge controls

If those requirements emerge, the preferred next step is usually:

- add `Cloudflare` proxy and edge security capabilities first

before considering:

- Azure `Application Gateway`
- GCP `Application Load Balancer`

This keeps the in-cluster architecture stable while adding capabilities at the
edge.

## Recommended Production Decision

The recommended production decision for this repository is:

- keep `Envoy Gateway` as the single ingress and routing layer in both clusters
- use one Azure `Standard Load Balancer` for AKS Envoy
- use one GCP external `Network Load Balancer` for GKE Envoy
- keep `Cloudflare DNS` as the failover DNS control point
- keep shared application failover DNS outside `external-dns`
- add Cloudflare proxy or WAF features only when there is a clear security or
  product requirement

## Summary

For production, the best fit for this repository is a shared, symmetric,
cost-aware architecture:

- one public Layer 4 load balancer per cluster
- one shared Envoy public ingress per cluster
- DNS-based active/passive failover through Cloudflare
- platform-managed TLS in both clusters
- no extra managed Layer 7 ingress products unless justified by a real
  requirement

This keeps the design portable, operationally clean, and significantly cheaper
than building separate managed ingress stacks on Azure and GCP while still
preserving a solid production baseline.
