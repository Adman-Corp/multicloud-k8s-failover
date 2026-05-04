location            = "eastus"
resource_group_name = "mc-aks-rg-dev"
cluster_name        = "mc-aks-dev"
kubernetes_version  = "1.29"

node_count   = 1
node_vm_size = "Standard_B2s"

vnet_name             = "mc-aks-vnet-dev"
subnet_name           = "mc-aks-subnet-dev"
vnet_address_space    = ["10.10.0.0/16"]
subnet_address_prefix = ["10.10.1.0/24"]

tags = {
  Project     = "multicloud-k8s-failover"
  Environment = "dev"
  ManagedBy   = "terraform"
}
