# Stateful Application Decision

## Purpose

This document captures the next architecture decision for stateful applications
in this repository.

The current platform direction is focused on stateless applications first. That
fits the existing active/passive Gateway and DNS failover model well.

For stateful applications, however, ingress failover is only part of the
problem. We also need to decide how the application's data and background work
will behave across Azure AKS and GCP GKE.

This document does not make that decision yet. It describes the options and the
recommended direction for the next design step.

## Why A Decision Is Needed

For a stateful application, successful DNS and Gateway failover does not by
itself guarantee a correct failover.

The application may also depend on:

- a database
- object storage
- queues or event streams
- background workers
- scheduled jobs
- sessions

If those dependencies are not designed for active/passive behavior, the platform
can appear healthy while the application is still incorrect.

Examples of failure modes:

- the standby cluster serves traffic but does not have the latest data
- both clusters process background jobs at the same time
- both clusters write to the same database without a clear single writer model
- object storage is available only from one cloud or region

## Current Assumption

For now, the repository should treat failover-ready applications as:

- stateless applications, or
- applications whose persistent dependencies already have a defined failover
  model outside this repository

This keeps the first platform version simpler and reduces the risk of treating
network failover as full application failover.

## Recommended Direction

The recommended first direction for stateful applications is:

- keep compute failover in Kubernetes
- keep the application active/passive across clusters
- move state management out of the clusters
- keep a single writer model for the database and background work

In practice, that means preferring shared external data services that both
clusters can reach, instead of trying to make the Kubernetes clusters own or
replicate state directly.

## Database Options

### Option 1: Shared External Database Service

Examples:

- a neutral managed Postgres provider
- a neutral managed MySQL provider
- a neutral managed MongoDB provider

Characteristics:

- both AKS and GKE connect to the same database endpoint
- one primary writer exists at a time
- application failover does not require database promotion during every cluster
  failover

Advantages:

- simplest failover model for the application
- least platform complexity
- lower split-brain risk

Disadvantages:

- the data plane is external to the clusters
- database failover becomes a separate concern from cluster failover

### Option 2: Single-Cloud Primary Database Reached From Both Clusters

Characteristics:

- the database lives in Azure or GCP
- both clusters connect to it
- application compute can fail over, but the database remains in one cloud

Advantages:

- simpler than cross-cloud database replication
- easier to operate than dual-cloud database promotion

Disadvantages:

- the application remains dependent on one cloud for data
- full cloud-level failover is incomplete

### Option 3: Cross-Cloud Database Replication And Promotion

Characteristics:

- one primary writer database
- one replica in the other cloud
- failover includes database promotion and application cutover

Advantages:

- stronger cloud-level failover story

Disadvantages:

- highest operational complexity
- promotion and rollback are harder
- async replication may introduce data loss windows
- write fencing becomes critical

This option should be treated as an advanced future design, not the first
implementation target.

## Object Storage Options

### Option 1: Shared External Object Storage

Examples:

- an S3-compatible provider reachable from both clouds
- a neutral object storage platform

Characteristics:

- both clusters use the same bucket or object namespace
- object storage does not need per-failover promotion

Advantages:

- simplest application behavior
- no bucket cutover during cluster failover

Disadvantages:

- storage is external to the clusters

### Option 2: Single-Cloud Object Storage Used By Both Clusters

Characteristics:

- one cloud hosts the bucket
- both clusters read and write to it

Advantages:

- simpler than cross-cloud replication

Disadvantages:

- storage remains coupled to one cloud

### Option 3: Replicated Object Storage Across Clouds

Characteristics:

- storage exists in both clouds
- replication or synchronization is required
- failover may require endpoint or bucket cutover logic

Advantages:

- stronger multi-cloud storage story

Disadvantages:

- more operational complexity
- consistency expectations must be clearly defined

## Recommended First Stateful Pattern

If this repository adds stateful applications next, the recommended first
pattern is:

- application compute is active/passive across AKS and GKE
- the database is external and single-writer
- object storage is external and shared
- only the active cluster runs background workers and scheduled jobs
- session state is stateless or moved to an external shared store

This gives a practical failover story without immediately taking on cross-cloud
database promotion and replicated storage complexity.

## Decision To Make

Before onboarding stateful applications, we need to make an explicit decision on
the target data model.

At minimum, decide:

- whether the first stateful design uses a shared external database
- whether object storage should be shared externally or remain cloud-local
- whether cloud-level data failover is in scope now or deferred
- how background jobs are fenced so only the active cluster performs them

## Suggested Initial Decision

The most pragmatic initial decision is:

- stateless applications proceed first
- stateful applications use shared external data services where possible
- true cross-cloud data failover is deferred until there is a concrete need

This keeps the platform design realistic while leaving room for a stronger
stateful failover model later.
