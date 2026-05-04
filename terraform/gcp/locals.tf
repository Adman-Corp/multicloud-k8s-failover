locals {
  # Random suffix for unique resource names
  suffix = random_id.suffix.hex

  # Cluster name with suffix
  cluster_name = "${var.cluster_name}-${local.suffix}"

  # VPC and subnet names with suffix
  vpc_name    = "${var.vpc_name}-${local.suffix}"
  subnet_name = "${var.subnet_name}-${local.suffix}"
}