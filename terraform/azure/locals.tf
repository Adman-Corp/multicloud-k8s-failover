locals {
  # Resource group name with timestamp suffix to ensure uniqueness (optional)
  resource_group_name = "${var.resource_group_name}-${formatdate("YYYYMMDD", timestamp())}"
  # Or just use var.resource_group_name if you prefer static name
  # resource_group_name = var.resource_group_name

  # Cluster name with timestamp suffix
  cluster_name = "${var.cluster_name}-${formatdate("YYYYMMDD", timestamp())}"

  # Use a random suffix for storage account (if needed for backend)
  # random_id = random_id.storage_suffix.hex
}