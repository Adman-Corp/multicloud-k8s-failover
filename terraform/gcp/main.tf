# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = local.vpc_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  mtu                     = 1460
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = local.subnet_name
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_cidr
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = cidrsubnet(var.vpc_cidr, 6, 1)
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = cidrsubnet(var.vpc_cidr, 8, 2)
  }
}

data "google_container_engine_versions" "gke" {
  provider       = google-beta
  project        = var.project_id
  location       = var.zone
  version_prefix = "${var.kubernetes_version}."
}

# GKE cluster
resource "google_container_cluster" "primary" {
  provider = google-beta

  name                = local.cluster_name
  project             = var.project_id
  location            = var.zone
  min_master_version  = var.kubernetes_version
  deletion_protection = false
  # Zonal cluster (free-tier control plane)
  # Use regional for HA (additional cost)
  # location = var.region

  # Free tier (default)
  # We'll use the default release channel to get free tier
  release_channel {
    channel = "REGULAR"
  }

  # Networking
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # Private cluster (optional) - disable for simplicity
  # private_cluster_config {
  #   enable_private_nodes    = true
  #   enable_private_endpoint = false
  #   master_ipv4_cidr_block  = "172.16.0.0/28"
  # }

  # Enable Workload Identity for External Secrets
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Remove default node pool (we'll create a separate one)
  remove_default_node_pool = true
  initial_node_count       = 1

  # Enable OIDC issuer (optional)
  # Enable for External Secrets (already part of workload identity)
  # depends on workload identity

  # Enable vertical pod autoscaling (optional)
  vertical_pod_autoscaling {
    enabled = false
  }

  # Enable horizontal pod autoscaling (optional)
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  # Maintenance policy
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # IP allocation policy (using secondary ranges)
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Node config (for default node pool, but we'll remove)
  # We'll create a separate node pool below
}

# Node pool
resource "google_container_node_pool" "primary_nodes" {
  provider = google-beta

  name               = "${local.cluster_name}-node-pool"
  project            = var.project_id
  location           = var.zone
  cluster            = google_container_cluster.primary.name
  initial_node_count = var.node_count
  version            = data.google_container_engine_versions.gke.latest_node_version

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = "pd-standard"
    image_type   = "COS_CONTAINERD"
    labels       = var.labels
    tags         = ["gke-node", local.cluster_name]

    # Enable workload identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Service account (default compute engine service account)
    # We can create a custom service account if needed
    service_account = "default"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = var.external_dns_namespace
  }

  depends_on = [google_container_node_pool.primary_nodes]
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = var.cert_manager_namespace
  }

  depends_on = [google_container_node_pool.primary_nodes]
}

resource "kubernetes_namespace" "envoy_gateway" {
  metadata {
    name = var.envoy_gateway_namespace
  }

  depends_on = [google_container_node_pool.primary_nodes]
}

resource "kubernetes_namespace" "platform_ingress" {
  metadata {
    name = var.platform_ingress_namespace
  }

  depends_on = [google_container_node_pool.primary_nodes]
}

resource "kubernetes_secret" "external_dns_cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = var.external_dns_namespace
  }

  data = {
    apiToken = var.external_dns_cloudflare_api_token
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.external_dns]
}

resource "kubernetes_secret" "cert_manager_cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = var.cert_manager_namespace
  }

  data = {
    apiToken = var.external_dns_cloudflare_api_token
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.cert_manager]
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = var.external_dns_chart_version
  namespace        = var.external_dns_namespace
  create_namespace = false

  set {
    name  = "provider.name"
    value = "cloudflare"
  }

  set {
    name  = "policy"
    value = "upsert-only"
  }

  set {
    name  = "registry"
    value = "txt"
  }

  set {
    name  = "txtOwnerId"
    value = google_container_cluster.primary.name
  }

  dynamic "set" {
    for_each = var.external_dns_domain_filters
    content {
      name  = "domainFilters[${set.key}]"
      value = set.value
    }
  }

  dynamic "set" {
    for_each = var.external_dns_cloudflare_zone_id == null ? [] : [var.external_dns_cloudflare_zone_id]
    content {
      name  = "extraArgs.zone-id-filter"
      value = set.value
    }
  }

  set {
    name  = "env[0].name"
    value = "CF_API_TOKEN"
  }

  set {
    name  = "env[0].valueFrom.secretKeyRef.name"
    value = kubernetes_secret.external_dns_cloudflare_api_token.metadata[0].name
  }

  set {
    name  = "env[0].valueFrom.secretKeyRef.key"
    value = "apiToken"
  }

  depends_on = [kubernetes_secret.external_dns_cloudflare_api_token]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_chart_version
  namespace        = var.cert_manager_namespace
  create_namespace = false

  set {
    name  = "crds.enabled"
    value = "true"
  }

  set {
    name  = "config.enableGatewayAPI"
    value = "true"
  }

  depends_on = [kubernetes_namespace.cert_manager, helm_release.envoy_gateway]
}

resource "helm_release" "cert_manager_bootstrap" {
  name             = "cert-manager-bootstrap"
  chart            = "../charts/cert-manager-bootstrap"
  namespace        = var.cert_manager_namespace
  create_namespace = false

  set {
    name  = "issuer.name"
    value = var.cert_manager_cluster_issuer_name
  }

  set {
    name  = "issuer.email"
    value = var.cert_manager_acme_email
  }

  set {
    name  = "issuer.server"
    value = var.cert_manager_acme_server
  }

  set {
    name  = "issuer.privateKeySecretName"
    value = "${var.cert_manager_cluster_issuer_name}-account-key"
  }

  depends_on = [helm_release.cert_manager, kubernetes_secret.cert_manager_cloudflare_api_token]
}

resource "helm_release" "envoy_gateway" {
  name             = "envoy-gateway"
  repository       = "oci://docker.io/envoyproxy"
  chart            = "gateway-helm"
  version          = var.envoy_gateway_chart_version
  namespace        = var.envoy_gateway_namespace
  create_namespace = false

  set {
    name  = "deployment.replicas"
    value = "2"
  }

  depends_on = [kubernetes_namespace.envoy_gateway]
}

resource "helm_release" "platform_bootstrap" {
  name             = "platform-bootstrap"
  chart            = "../charts/platform-bootstrap"
  namespace        = var.platform_ingress_namespace
  create_namespace = false

  set {
    name  = "gateway.hostname"
    value = var.platform_gateway_wildcard
  }

  set {
    name  = "gateway.namespace"
    value = var.platform_ingress_namespace
  }

  depends_on = [helm_release.envoy_gateway, kubernetes_namespace.platform_ingress]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.5.11"
  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "server.ingress.enabled"
    value = "false"
  }

  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  depends_on = [helm_release.external_dns, helm_release.cert_manager_bootstrap, helm_release.envoy_gateway]
}

resource "helm_release" "argocd_bootstrap" {
  count            = var.argocd_hostname == null ? 0 : 1
  name             = "argocd-bootstrap"
  chart            = "../charts/argocd-bootstrap"
  namespace        = var.platform_ingress_namespace
  create_namespace = false

  set {
    name  = "argocd.namespace"
    value = "argocd"
  }

  set {
    name  = "argocd.hostname"
    value = var.argocd_hostname
  }

  depends_on = [helm_release.platform_bootstrap, helm_release.argocd, helm_release.external_dns, kubernetes_namespace.platform_ingress]
}

# Outputs will be defined in outputs.tf
