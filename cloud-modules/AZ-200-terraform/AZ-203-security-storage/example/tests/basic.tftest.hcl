# Tests for AZ-203: Security & Storage
# Uses mock_provider to test configuration without real Azure credentials.
# Validates Storage Account, Managed Disk, and Key Vault configuration.

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id   = "00000000-0000-0000-0000-000000000002"
      client_id   = "00000000-0000-0000-0000-000000000003"
      object_id   = "00000000-0000-0000-0000-000000000004"
    }
  }
}

# ---------------------------------------------------------------
# Test 1: Default variables produce a valid plan
# ---------------------------------------------------------------
run "default_variables" {
  command = plan

  variables {
    subscription_id = "00000000-0000-0000-0000-000000000001"
  }

  assert {
    condition     = azurerm_resource_group.main.name == "az203-rg"
    error_message = "Resource group name should use project_name prefix"
  }

  assert {
    condition     = azurerm_storage_account.main.name == "az203devsa"
    error_message = "Storage account name should combine project_name and environment"
  }
}

# ---------------------------------------------------------------
# Test 2: Storage account is configured securely
# ---------------------------------------------------------------
run "storage_account_security" {
  command = plan

  variables {
    subscription_id = "00000000-0000-0000-0000-000000000001"
  }

  assert {
    condition     = azurerm_storage_account.main.account_tier == "Standard"
    error_message = "Storage account tier should be Standard"
  }

  assert {
    condition     = azurerm_storage_account.main.account_replication_type == "LRS"
    error_message = "Storage account replication type should be LRS"
  }

  assert {
    condition     = azurerm_storage_account.main.blob_properties[0].versioning_enabled == true
    error_message = "Storage account blob versioning should be enabled"
  }
}

# ---------------------------------------------------------------
# Test 3: Storage container is private
# ---------------------------------------------------------------
run "storage_container_private" {
  command = plan

  variables {
    subscription_id = "00000000-0000-0000-0000-000000000001"
  }

  assert {
    condition     = azurerm_storage_container.data.name == "data"
    error_message = "Storage container name should be 'data'"
  }

  assert {
    condition     = azurerm_storage_container.data.container_access_type == "private"
    error_message = "Storage container should be private"
  }
}

# ---------------------------------------------------------------
# Test 4: Managed disk is configured correctly
# ---------------------------------------------------------------
run "managed_disk_config" {
  command = plan

  variables {
    subscription_id = "00000000-0000-0000-0000-000000000001"
  }

  assert {
    condition     = azurerm_managed_disk.data.disk_size_gb == 32
    error_message = "Managed disk size should be 32 GB by default"
  }

  assert {
    condition     = azurerm_managed_disk.data.storage_account_type == "Standard_LRS"
    error_message = "Managed disk storage type should be Standard_LRS"
  }

  assert {
    condition     = azurerm_managed_disk.data.create_option == "Empty"
    error_message = "Managed disk create option should be Empty"
  }
}

# ---------------------------------------------------------------
# Test 5: Key Vault uses mocked tenant and object IDs
# ---------------------------------------------------------------
run "key_vault_config" {
  command = plan

  variables {
    subscription_id = "00000000-0000-0000-0000-000000000001"
  }

  assert {
    condition     = azurerm_key_vault.main.name == "az203-kv"
    error_message = "Key Vault name should use project_name prefix"
  }

  assert {
    condition     = azurerm_key_vault.main.tenant_id == "00000000-0000-0000-0000-000000000002"
    error_message = "Key Vault tenant_id should come from the mocked client config"
  }

  assert {
    condition     = azurerm_key_vault.main.sku_name == "standard"
    error_message = "Key Vault SKU should be standard"
  }
}

# ---------------------------------------------------------------
# Test 6: Custom disk size validation
# ---------------------------------------------------------------
run "custom_disk_size" {
  command = plan

  variables {
    subscription_id = "00000000-0000-0000-0000-000000000001"
    disk_size_gb    = 64
  }

  assert {
    condition     = azurerm_managed_disk.data.disk_size_gb == 64
    error_message = "Managed disk size should reflect the custom variable"
  }
}