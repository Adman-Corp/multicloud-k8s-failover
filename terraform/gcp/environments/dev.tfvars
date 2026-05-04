project_id = "adman-k8s-failover-dev-260502"
region     = "us-central1"
zone       = "us-central1-a"

cluster_name       = "mc-gke-dev"
kubernetes_version = "1.35"
argocd_hostname    = "argocd.gcp.admancorp.com"

node_count        = 1
node_machine_type = "e2-small"
node_disk_size_gb = 30

vpc_name    = "mc-gke-vpc-dev"
subnet_name = "mc-gke-subnet-dev"
vpc_cidr    = "10.11.0.0/16"
subnet_cidr = "10.11.1.0/24"

workload_identity_enabled = true

labels = {
  project     = "multicloud-k8s-failover"
  environment = "dev"
  managed-by  = "terraform"
}
