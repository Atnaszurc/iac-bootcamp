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

data "ibm_resource_group" "target" {
  is_default = var.resource_group_name == "Default" ? true : null
  name       = var.resource_group_name == "Default" ? null : var.resource_group_name
}

locals {
  environment = lower(var.environment)
  common_tags = [
    "training",
    "ibm-cloud",
    "terraform",
    "environment:${local.environment}",
  ]
}

output "provider_source" {
  description = "Terraform provider source used for this lesson."
  value       = "IBM-Cloud/ibm"
}

output "provider_region" {
  description = "IBM Cloud region configured in the provider."
  value       = var.ibm_region
}

output "resource_group_name" {
  description = "Resolved IBM Cloud resource group name."
  value       = data.ibm_resource_group.target.name
}

output "resource_group_id" {
  description = "Resolved IBM Cloud resource group ID."
  value       = data.ibm_resource_group.target.id
}

output "environment" {
  description = "Normalized environment label for later modules."
  value       = local.environment
}

output "common_tags" {
  description = "Starter tags that can be reused in later IBM modules."
  value       = local.common_tags
}
