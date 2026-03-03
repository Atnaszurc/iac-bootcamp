# AZ-203: Security & Storage
# Demonstrates: Storage Account, Managed Disk, Key Vault, RBAC role assignment
# Provider: hashicorp/azurerm
# Run: terraform init && terraform apply
#
# Prerequisites: Azure credentials configured (see AZ-201)
# Cost: Storage LRS ~$0.018/GB/month; Key Vault ~$0.03/10k operations

terraform {
  required_version = ">= 1.14"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = var.subscription_id
}

# ─────────────────────────────────────────────────────────────────────────────
# Data sources
# ─────────────────────────────────────────────────────────────────────────────

data "azurerm_client_config" "current" {}

# ─────────────────────────────────────────────────────────────────────────────
# Resource Group
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg"
  location = var.location

  tags = {
    ManagedBy   = "Terraform"
    Course      = "AZ-203"
    Environment = var.environment
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Storage Account
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_storage_account" "main" {
  name                     = "${var.project_name}${var.environment}sa"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# ─────────────────────────────────────────────────────────────────────────────
# Managed Disk
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_managed_disk" "data" {
  name                 = "${var.project_name}-data-disk"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.disk_size_gb

  tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Key Vault
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_key_vault" "main" {
  name                = "${var.project_name}-kv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Allow the current Terraform principal to manage secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]
  }

  tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "azurerm_key_vault_secret" "example" {
  name         = "example-secret"
  value        = "super-secret-value-replace-me"
  key_vault_id = azurerm_key_vault.main.id
}

# ─────────────────────────────────────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────────────────────────────────────

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "managed_disk_id" {
  description = "ID of the managed disk"
  value       = azurerm_managed_disk.data.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}