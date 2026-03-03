# AZ-201: Setup & Authentication
# Demonstrates: Azure provider configuration, authentication methods
# Provider: hashicorp/azurerm
# Run: terraform init && terraform plan
#
# Prerequisites:
#   - Azure CLI installed and logged in (az login)
#   - OR environment variables: ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
#   - OR Managed Identity (when running on Azure VMs/ACI/AKS)
#
# See: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs

terraform {
  required_version = ">= 1.14"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider configuration
# Authentication is resolved in this order:
#   1. Azure CLI (az login) — best for local development
#   2. Service Principal with client secret (ARM_* env vars)
#   3. Service Principal with certificate
#   4. Managed Identity (Azure-hosted workloads)
# ─────────────────────────────────────────────────────────────────────────────

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id

  # Optional: use a service principal
  # client_id       = var.client_id
  # client_secret   = var.client_secret
  # tenant_id       = var.tenant_id
}

# ─────────────────────────────────────────────────────────────────────────────
# Verify authentication: read subscription and client info
# ─────────────────────────────────────────────────────────────────────────────

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

# ─────────────────────────────────────────────────────────────────────────────
# Outputs — verify what subscription/tenant we're connected to
# ─────────────────────────────────────────────────────────────────────────────

output "subscription_id" {
  description = "Azure subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
}

output "subscription_display_name" {
  description = "Azure subscription display name"
  value       = data.azurerm_subscription.current.display_name
}

output "tenant_id" {
  description = "Azure tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "client_id" {
  description = "Client ID (service principal or user)"
  value       = data.azurerm_client_config.current.client_id
}