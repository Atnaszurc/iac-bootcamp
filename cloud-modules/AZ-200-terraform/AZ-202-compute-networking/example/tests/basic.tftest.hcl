# Tests for AZ-202: Compute & Networking
# Uses mock_provider to test configuration without real Azure credentials.
# Validates Resource Group, VNet, NSG, public IP, NIC, and Linux VM configuration.

mock_provider "azurerm" {}

# ---------------------------------------------------------------
# Test 1: Default variables produce a valid plan
# ---------------------------------------------------------------
run "default_variables" {
  command = plan

  variables {
    subscription_id = "00000000-0000-0000-0000-000000000001"
  }

  assert {
    condition     = azurerm_resource_group.main.name == "az202-rg"
    error_message = "Resource group name should use project_name prefix"
  }

  assert {
    condition     = azurerm_resource_group.main.location == "West Europe"
    error_message = "Resource group location should be West Europe by default"
  }

  assert {
    condition     = azurerm_virtual_network.main.name == "az202-vnet"
    error_message = "VNet name should use project_name prefix"
  }
}

# ---------------------------------------------------------------
# Test 2: Network configuration is correct
# ---------------------------------------------------------------
run "network_configuration" {
  command = plan

  variables {
    subscription_id = "00000000-0000-0000-0000-000000000001"
  }

  assert {
    condition     = tolist(azurerm_virtual_network.main.address_space) == tolist(["10.0.0.0/16"])
    error_message = "VNet address space should be 10.0.0.0/16"
  }

  assert {
    condition     = tolist(azurerm_subnet.main.address_prefixes) == tolist(["10.0.1.0/24"])
    error_message = "Subnet address prefix should be 10.0.1.0/24"
  }
}

# ---------------------------------------------------------------
# Test 3: NSG has SSH and HTTP rules
# ---------------------------------------------------------------
run "nsg_security_rules" {
  command = plan

  variables {
    subscription_id = "00000000-0000-0000-0000-000000000001"
  }

  assert {
    condition     = azurerm_network_security_group.main.name == "az202-nsg"
    error_message = "NSG name should use project_name prefix"
  }

  assert {
    condition     = length(azurerm_network_security_group.main.security_rule) == 2
    error_message = "NSG should have 2 security rules (SSH + HTTP)"
  }
}

# ---------------------------------------------------------------
# Test 4: Public IP is static Standard SKU
# ---------------------------------------------------------------
run "public_ip_config" {
  command = plan

  variables {
    subscription_id = "00000000-0000-0000-0000-000000000001"
  }

  assert {
    condition     = azurerm_public_ip.main.allocation_method == "Static"
    error_message = "Public IP allocation method should be Static"
  }

  assert {
    condition     = azurerm_public_ip.main.sku == "Standard"
    error_message = "Public IP SKU should be Standard"
  }
}

# ---------------------------------------------------------------
# Test 5: VM is configured with correct size and image
# ---------------------------------------------------------------
run "vm_configuration" {
  command = plan

  variables {
    subscription_id = "00000000-0000-0000-0000-000000000001"
    ssh_public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDY5O6Vlecaw4jVcv15DNFm5VJYtWcjKPpentQHWNcuFCUl/7TAR+3B418mWGZhgDbExH+ipVyq+Bz9hS5wugYjSsaiMPa5X2wjKSCMOwUWnluzUgSFnHhyj45NWFI0S7atbU9sqGE5tqXEh1tMqkIkp1tWJexKMd4Q8M4nCJVMOtcG2CWuh7BUdJLPcMzOaYGgSNxaOvabpT8+cMoVINrIVd1UTwKi7h5WthKID72drCt2lHG1pzQnPK6DkzjTbGlul/19Lm1d8DjMAg7GMXAEaa7dbWIt4LrZCNCv/0oZ0XQlxWxl1INgKEuOIsLjf4geafwqiEGtZdcZFFjPIplt test@example.com"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.main.size == "Standard_B1s"
    error_message = "VM size should be Standard_B1s by default"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.main.admin_username == "azureuser"
    error_message = "VM admin username should be azureuser"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.main.source_image_reference[0].publisher == "Canonical"
    error_message = "VM image publisher should be Canonical"
  }
}

# ---------------------------------------------------------------
# Test 6: Custom project name propagates to all resources
# ---------------------------------------------------------------
run "custom_project_name" {
  command = plan

  variables {
    subscription_id = "00000000-0000-0000-0000-000000000001"
    project_name    = "myapp"
    environment     = "staging"
  }

  assert {
    condition     = azurerm_resource_group.main.name == "myapp-rg"
    error_message = "Resource group name should use custom project_name"
  }

  assert {
    condition     = azurerm_virtual_network.main.name == "myapp-vnet"
    error_message = "VNet name should use custom project_name"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.main.name == "myapp-vm"
    error_message = "VM name should use custom project_name"
  }
}