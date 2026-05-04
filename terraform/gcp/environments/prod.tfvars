project_id = "adman-k8s-failover-260502"
region     = "us-central1"
zone       = "us-central1-a"

cluster_name       = "mc-gke"
kubernetes_version = "1.34"

node_count        = 1
node_machine_type = "e2-small"
node_disk_size_gb = 30

vpc_name    = "mc-gke-vpc"
subnet_name = "mc-gke-subnet"
vpc_cidr    = "10.1.0.0/16"
subnet_cidr = "10.1.1.0/24"

workload_identity_enabled = true

labels = {
  project     = "multicloud-k8s-failover"
  environment = "prod"
  managed-by  = "terraform"
}
