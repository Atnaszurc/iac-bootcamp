# MC-301: Multi-Cloud Strategy & Design - Outputs
# Demonstrates normalized outputs across both cloud providers

# ---------------------------------------------------------------------------
# Configuration summary
# ---------------------------------------------------------------------------

output "project_name" {
  description = "Project name used across all resources"
  value       = var.project_name
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "name_prefix" {
  description = "Consistent name prefix used across all resources"
  value       = local.name_prefix
}

output "active_config" {
  description = "Active environment configuration (instance sizes and replica count)"
  value       = local.config
}

output "common_tags" {
  description = "Common tags applied to all resources across both clouds"
  value       = local.common_tags
}

# ---------------------------------------------------------------------------
# AWS outputs
# ---------------------------------------------------------------------------

output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.main.id
}

output "aws_vpc_cidr" {
  description = "AWS VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "aws_subnet_id" {
  description = "AWS public subnet ID"
  value       = aws_subnet.public.id
}

output "aws_s3_bucket_name" {
  description = "AWS S3 bucket name for shared storage"
  value       = aws_s3_bucket.shared.id
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# ---------------------------------------------------------------------------
# Azure outputs
# ---------------------------------------------------------------------------

output "azure_resource_group_name" {
  description = "Azure resource group name"
  value       = azurerm_resource_group.main.name
}

output "azure_resource_group_location" {
  description = "Azure resource group location"
  value       = azurerm_resource_group.main.location
}

output "azure_vnet_id" {
  description = "Azure Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "azure_vnet_cidr" {
  description = "Azure VNet address space"
  value       = tolist(azurerm_virtual_network.main.address_space)[0]
}

output "azure_subnet_id" {
  description = "Azure public subnet ID"
  value       = azurerm_subnet.public.id
}

output "azure_storage_account_name" {
  description = "Azure storage account name"
  value       = azurerm_storage_account.main.name
}

# ---------------------------------------------------------------------------
# Multi-cloud summary
# ---------------------------------------------------------------------------

output "multi_cloud_summary" {
  description = "Summary of resources deployed across both clouds"
  value = {
    aws = {
      region  = var.aws_region
      vpc     = aws_vpc.main.cidr_block
      storage = aws_s3_bucket.shared.id
    }
    azure = {
      region  = var.azure_region
      vnet    = tolist(azurerm_virtual_network.main.address_space)[0]
      storage = azurerm_storage_account.main.name
    }
    shared = {
      project     = var.project_name
      environment = var.environment
      cost_center = var.cost_center
    }
  }
}