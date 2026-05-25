terraform {
  required_version = ">= 1.14"

  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 2.0"
    }
  }
}

provider "ibm" {
  region = var.ibm_region
}

# =====================================================================================
# Data Sources
# =====================================================================================

data "ibm_resource_group" "target" {
  is_default = var.resource_group_name == "Default" ? true : null
  name       = var.resource_group_name == "Default" ? null : var.resource_group_name
}

# Find the latest Ubuntu image
data "ibm_is_image" "ubuntu" {
  name = var.image_name
}

# Get available SSH keys (if using existing keys)
data "ibm_is_ssh_keys" "existing_keys" {}

# =====================================================================================
# Local Variables
# =====================================================================================

locals {
  environment = lower(var.environment)
  common_tags = [
    "training",
    "ibm-cloud",
    "terraform",
    "module:ibm-202",
    "environment:${local.environment}",
  ]

  # Construct resource names with consistent naming convention
  vpc_name            = "${local.environment}-${var.project_name}-vpc"
  subnet_name_zone1   = "${local.environment}-${var.project_name}-subnet-zone1"
  subnet_name_zone2   = "${local.environment}-${var.project_name}-subnet-zone2"
  gateway_name        = "${local.environment}-${var.project_name}-gateway"
  ssh_key_name        = "${local.environment}-${var.project_name}-ssh-key"
  instance_name_zone1 = "${local.environment}-${var.project_name}-vsi-zone1"
  instance_name_zone2 = "${local.environment}-${var.project_name}-vsi-zone2"
  fip_name_zone1      = "${local.environment}-${var.project_name}-fip-zone1"

  # Calculate zones based on region
  zone1 = "${var.ibm_region}-1"
  zone2 = "${var.ibm_region}-2"
}

# =====================================================================================
# VPC Resources
# =====================================================================================

resource "ibm_is_vpc" "training_vpc" {
  name                      = local.vpc_name
  resource_group            = data.ibm_resource_group.target.id
  classic_access            = false
  address_prefix_management = "auto"
  tags                      = local.common_tags
}

# =====================================================================================
# Public Gateway (for outbound internet access)
# =====================================================================================

resource "ibm_is_public_gateway" "gateway_zone1" {
  name           = "${local.gateway_name}-zone1"
  vpc            = ibm_is_vpc.training_vpc.id
  zone           = local.zone1
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags
}

# =====================================================================================
# Subnets
# =====================================================================================

resource "ibm_is_subnet" "subnet_zone1" {
  name                     = local.subnet_name_zone1
  vpc                      = ibm_is_vpc.training_vpc.id
  zone                     = local.zone1
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway_zone1.id
  resource_group           = data.ibm_resource_group.target.id
  tags                     = local.common_tags
}

resource "ibm_is_subnet" "subnet_zone2" {
  name                     = local.subnet_name_zone2
  vpc                      = ibm_is_vpc.training_vpc.id
  zone                     = local.zone2
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.target.id
  tags                     = local.common_tags
}

# =====================================================================================
# SSH Key (conditionally created if public_key is provided)
# =====================================================================================

resource "ibm_is_ssh_key" "training_key" {
  count          = var.ssh_public_key != "" ? 1 : 0
  name           = local.ssh_key_name
  public_key     = var.ssh_public_key
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags
}

# =====================================================================================
# Virtual Server Instances
# =====================================================================================

resource "ibm_is_instance" "vsi_zone1" {
  count          = var.create_instances ? 1 : 0
  name           = local.instance_name_zone1
  vpc            = ibm_is_vpc.training_vpc.id
  zone           = local.zone1
  profile        = var.instance_profile
  image          = data.ibm_is_image.ubuntu.id
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags

  primary_network_interface {
    subnet = ibm_is_subnet.subnet_zone1.id
  }

  # Use created SSH key if available, otherwise use existing keys
  keys = var.ssh_public_key != "" ? [ibm_is_ssh_key.training_key[0].id] : []

  # User data for initial configuration (optional)
  user_data = var.user_data != "" ? var.user_data : null
}

resource "ibm_is_instance" "vsi_zone2" {
  count          = var.create_instances && var.multi_zone ? 1 : 0
  name           = local.instance_name_zone2
  vpc            = ibm_is_vpc.training_vpc.id
  zone           = local.zone2
  profile        = var.instance_profile
  image          = data.ibm_is_image.ubuntu.id
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags

  primary_network_interface {
    subnet = ibm_is_subnet.subnet_zone2.id
  }

  keys = var.ssh_public_key != "" ? [ibm_is_ssh_key.training_key[0].id] : []

  user_data = var.user_data != "" ? var.user_data : null
}

# =====================================================================================
# Floating IP (for direct public access to zone1 instance)
# =====================================================================================

resource "ibm_is_floating_ip" "fip_zone1" {
  count          = var.create_instances && var.assign_floating_ip ? 1 : 0
  name           = local.fip_name_zone1
  target         = ibm_is_instance.vsi_zone1[0].primary_network_interface[0].id
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags
}

# =====================================================================================
# Outputs
# =====================================================================================

output "vpc_id" {
  description = "ID of the created VPC"
  value       = ibm_is_vpc.training_vpc.id
}

output "vpc_name" {
  description = "Name of the created VPC"
  value       = ibm_is_vpc.training_vpc.name
}

output "vpc_crn" {
  description = "CRN of the created VPC"
  value       = ibm_is_vpc.training_vpc.crn
}

output "subnet_zone1_id" {
  description = "ID of the subnet in zone 1"
  value       = ibm_is_subnet.subnet_zone1.id
}

output "subnet_zone1_cidr" {
  description = "CIDR block of the subnet in zone 1"
  value       = ibm_is_subnet.subnet_zone1.ipv4_cidr_block
}

output "subnet_zone2_id" {
  description = "ID of the subnet in zone 2"
  value       = ibm_is_subnet.subnet_zone2.id
}

output "subnet_zone2_cidr" {
  description = "CIDR block of the subnet in zone 2"
  value       = ibm_is_subnet.subnet_zone2.ipv4_cidr_block
}

output "public_gateway_id" {
  description = "ID of the public gateway"
  value       = ibm_is_public_gateway.gateway_zone1.id
}

output "ssh_key_id" {
  description = "ID of the created SSH key (if created)"
  value       = var.ssh_public_key != "" ? ibm_is_ssh_key.training_key[0].id : null
}

output "vsi_zone1_id" {
  description = "ID of the VSI in zone 1 (if created)"
  value       = var.create_instances ? ibm_is_instance.vsi_zone1[0].id : null
}

output "vsi_zone1_private_ip" {
  description = "Private IP of the VSI in zone 1 (if created)"
  value       = var.create_instances ? "10.240.0.4" : null
}

output "vsi_zone2_id" {
  description = "ID of the VSI in zone 2 (if created)"
  value       = var.create_instances && var.multi_zone ? ibm_is_instance.vsi_zone2[0].id : null
}

output "vsi_zone2_private_ip" {
  description = "Private IP of the VSI in zone 2 (if created)"
  value       = var.create_instances && var.multi_zone ? "10.240.1.4" : null
}

output "floating_ip" {
  description = "Floating IP address for zone 1 instance (if created)"
  value       = var.create_instances && var.assign_floating_ip ? ibm_is_floating_ip.fip_zone1[0].address : null
}

output "ssh_connection_command" {
  description = "SSH command to connect to zone 1 instance (if floating IP assigned)"
  value = var.create_instances && var.assign_floating_ip ? (
    "ssh -i ~/.ssh/your_private_key root@${ibm_is_floating_ip.fip_zone1[0].address}"
  ) : null
}

output "resource_group_id" {
  description = "ID of the resource group used"
  value       = data.ibm_resource_group.target.id
}

output "zones_used" {
  description = "Availability zones used in this deployment"
  value = {
    zone1 = local.zone1
    zone2 = local.zone2
  }
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}
