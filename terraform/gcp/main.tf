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
    ip_cidr_range = "10.1.2.0/22"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.1.6.0/24"
  }
}

# GKE cluster
resource "google_container_cluster" "primary" {
  provider = google-beta

  name     = local.cluster_name
  project  = var.project_id
  location = var.zone
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

  name       = "${local.cluster_name}-node-pool"
  project    = var.project_id
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

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
}

# Outputs will be defined in outputs.tf