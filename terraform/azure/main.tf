# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# SSH key for AKS nodes
resource "tls_private_key" "aks_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.resource_group_name}-${random_id.suffix.hex}"
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.vnet_name}-${random_id.suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Subnet
resource "azurerm_subnet" "aks" {
  name                 = "${var.subnet_name}-${random_id.suffix.hex}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_address_prefix
}

# Managed Identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "aks-identity-${random_id.suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# AKS cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.cluster_name}-${random_id.suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.cluster_name}-${random_id.suffix.hex}"
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  # Free-tier control plane
  sku_tier = "Free"

  # OIDC issuer enabled for External Secrets
  oidc_issuer_enabled = true

  # Managed identity
  identity {
    type = "SystemAssigned"
  }

  # Linux profile (optional)
  linux_profile {
    admin_username = "ubuntu"
    ssh_key {
      key_data = tls_private_key.aks_ssh.public_key_openssh
    }
  }

  default_node_pool {
    name           = "default"
    node_count     = var.node_count
    vm_size        = var.node_vm_size
    vnet_subnet_id = azurerm_subnet.aks.id
    type           = "VirtualMachineScaleSets"
    os_sku         = "Ubuntu"
    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
    # Enable auto-scaling if desired
    # enable_auto_scaling = true
    # min_count = 1
    # max_count = 3
  }

  # Network profile
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    service_cidr      = "10.0.2.0/24"
    dns_service_ip    = "10.0.2.10"
    load_balancer_sku = "standard"
  }

  # Enable Azure Policy (optional)
  # azure_policy_enabled = true

  # Enable monitoring (optional)
  # oms_agent {
  #   log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  # }
}

resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = var.external_dns_namespace
  }

  depends_on = [azurerm_kubernetes_cluster.main]
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
    value = azurerm_kubernetes_cluster.main.name
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

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.5.11"
  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  dynamic "set" {
    for_each = var.argocd_hostname == null ? [] : [var.argocd_hostname]
    content {
      name  = "server.service.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
      value = set.value
    }
  }

  depends_on = [helm_release.external_dns]
}

# Role assignment for managed identity (if needed)
# resource "azurerm_role_assignment" "aks_network" {
#   principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
#   role_definition_name = "Network Contributor"
#   scope                = azurerm_subnet.aks.id
# }
