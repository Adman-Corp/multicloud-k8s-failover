project_id = "adman-k8s-failover-uat-260502"
region     = "us-central1"
zone       = "us-central1-a"

cluster_name            = "mc-gke-uat"
kubernetes_version      = "1.35"
cert_manager_acme_email = "younesse.adman+gcp@gmail.com"

node_count        = 1
node_machine_type = "e2-medium"
node_disk_size_gb = 30

vpc_name    = "mc-gke-vpc-uat"
subnet_name = "mc-gke-subnet-uat"
vpc_cidr    = "10.21.0.0/16"
subnet_cidr = "10.21.1.0/24"

workload_identity_enabled = true

labels = {
  project     = "multicloud-k8s-failover"
  environment = "uat"
  managed-by  = "terraform"
}
