location            = "eastus"
resource_group_name = "mc-aks-rg-uat"
cluster_name        = "mc-aks-uat"
kubernetes_version  = "1.29"

node_count   = 1
node_vm_size = "Standard_B2s"

vnet_name             = "mc-aks-vnet-uat"
subnet_name           = "mc-aks-subnet-uat"
vnet_address_space    = ["10.20.0.0/16"]
subnet_address_prefix = ["10.20.1.0/24"]

tags = {
  Project     = "multicloud-k8s-failover"
  Environment = "uat"
  ManagedBy   = "terraform"
}
