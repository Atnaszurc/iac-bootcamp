# Tests for AZ-204: Advanced Patterns
# Uses mock_provider to test configuration without real Azure credentials.
# Validates VM Scale Set, Azure Load Balancer, and autoscale configuration.

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
    subscription_id      = "00000000-0000-0000-0000-000000000001"
    admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDY5O6Vlecaw4jVcv15DNFm5VJYtWcjKPpentQHWNcuFCUl/7TAR+3B418mWGZhgDbExH+ipVyq+Bz9hS5wugYjSsaiMPa5X2wjKSCMOwUWnluzUgSFnHhyj45NWFI0S7atbU9sqGE5tqXEh1tMqkIkp1tWJexKMd4Q8M4nCJVMOtcG2CWuh7BUdJLPcMzOaYGgSNxaOvabpT8+cMoVINrIVd1UTwKi7h5WthKID72drCt2lHG1pzQnPK6DkzjTbGlul/19Lm1d8DjMAg7GMXAEaa7dbWIt4LrZCNCv/0oZ0XQlxWxl1INgKEuOIsLjf4geafwqiEGtZdcZFFjPIplt test@example.com"
  }

  assert {
    condition     = azurerm_resource_group.main.name == "az204-rg"
    error_message = "Resource group name should use project_name prefix"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.main.name == "az204-vmss"
    error_message = "VMSS name should use project_name prefix"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.main.instances == 2
    error_message = "VMSS should have 2 instances by default"
  }
}

# ---------------------------------------------------------------
# Test 2: Load balancer is configured correctly
# ---------------------------------------------------------------
run "load_balancer_config" {
  command = plan

  variables {
    subscription_id      = "00000000-0000-0000-0000-000000000001"
    admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDY5O6Vlecaw4jVcv15DNFm5VJYtWcjKPpentQHWNcuFCUl/7TAR+3B418mWGZhgDbExH+ipVyq+Bz9hS5wugYjSsaiMPa5X2wjKSCMOwUWnluzUgSFnHhyj45NWFI0S7atbU9sqGE5tqXEh1tMqkIkp1tWJexKMd4Q8M4nCJVMOtcG2CWuh7BUdJLPcMzOaYGgSNxaOvabpT8+cMoVINrIVd1UTwKi7h5WthKID72drCt2lHG1pzQnPK6DkzjTbGlul/19Lm1d8DjMAg7GMXAEaa7dbWIt4LrZCNCv/0oZ0XQlxWxl1INgKEuOIsLjf4geafwqiEGtZdcZFFjPIplt test@example.com"
  }

  assert {
    condition     = azurerm_lb.main.sku == "Standard"
    error_message = "Load balancer SKU should be Standard"
  }

  assert {
    condition     = azurerm_lb.main.name == "az204-lb"
    error_message = "Load balancer name should use project_name prefix"
  }

  assert {
    condition     = azurerm_public_ip.lb.allocation_method == "Static"
    error_message = "Load balancer public IP should be Static"
  }

  assert {
    condition     = azurerm_public_ip.lb.sku == "Standard"
    error_message = "Load balancer public IP SKU should be Standard"
  }
}

# ---------------------------------------------------------------
# Test 3: VMSS uses correct image and size
# ---------------------------------------------------------------
run "vmss_image_config" {
  command = plan

  variables {
    subscription_id      = "00000000-0000-0000-0000-000000000001"
    admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDY5O6Vlecaw4jVcv15DNFm5VJYtWcjKPpentQHWNcuFCUl/7TAR+3B418mWGZhgDbExH+ipVyq+Bz9hS5wugYjSsaiMPa5X2wjKSCMOwUWnluzUgSFnHhyj45NWFI0S7atbU9sqGE5tqXEh1tMqkIkp1tWJexKMd4Q8M4nCJVMOtcG2CWuh7BUdJLPcMzOaYGgSNxaOvabpT8+cMoVINrIVd1UTwKi7h5WthKID72drCt2lHG1pzQnPK6DkzjTbGlul/19Lm1d8DjMAg7GMXAEaa7dbWIt4LrZCNCv/0oZ0XQlxWxl1INgKEuOIsLjf4geafwqiEGtZdcZFFjPIplt test@example.com"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.main.sku == "Standard_B1s"
    error_message = "VMSS SKU should be Standard_B1s by default"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.main.source_image_reference[0].publisher == "Canonical"
    error_message = "VMSS image publisher should be Canonical"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.main.admin_username == "azureuser"
    error_message = "VMSS admin username should be azureuser by default"
  }
}

# ---------------------------------------------------------------
# Test 4: Autoscale settings are configured
# ---------------------------------------------------------------
run "autoscale_config" {
  command = plan

  variables {
    subscription_id      = "00000000-0000-0000-0000-000000000001"
    admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDY5O6Vlecaw4jVcv15DNFm5VJYtWcjKPpentQHWNcuFCUl/7TAR+3B418mWGZhgDbExH+ipVyq+Bz9hS5wugYjSsaiMPa5X2wjKSCMOwUWnluzUgSFnHhyj45NWFI0S7atbU9sqGE5tqXEh1tMqkIkp1tWJexKMd4Q8M4nCJVMOtcG2CWuh7BUdJLPcMzOaYGgSNxaOvabpT8+cMoVINrIVd1UTwKi7h5WthKID72drCt2lHG1pzQnPK6DkzjTbGlul/19Lm1d8DjMAg7GMXAEaa7dbWIt4LrZCNCv/0oZ0XQlxWxl1INgKEuOIsLjf4geafwqiEGtZdcZFFjPIplt test@example.com"
  }

  assert {
    condition     = azurerm_monitor_autoscale_setting.main.name == "az204-autoscale"
    error_message = "Autoscale setting name should use project_name prefix"
  }

  assert {
    condition     = azurerm_monitor_autoscale_setting.main.profile[0].capacity[0].minimum == 1
    error_message = "Autoscale minimum capacity should be 1 by default"
  }

  assert {
    condition     = azurerm_monitor_autoscale_setting.main.profile[0].capacity[0].maximum == 5
    error_message = "Autoscale maximum capacity should be 5 by default"
  }
}

# ---------------------------------------------------------------
# Test 5: Custom instance count and scaling limits
# ---------------------------------------------------------------
run "custom_scaling" {
  command = plan

  variables {
    subscription_id      = "00000000-0000-0000-0000-000000000001"
    admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDY5O6Vlecaw4jVcv15DNFm5VJYtWcjKPpentQHWNcuFCUl/7TAR+3B418mWGZhgDbExH+ipVyq+Bz9hS5wugYjSsaiMPa5X2wjKSCMOwUWnluzUgSFnHhyj45NWFI0S7atbU9sqGE5tqXEh1tMqkIkp1tWJexKMd4Q8M4nCJVMOtcG2CWuh7BUdJLPcMzOaYGgSNxaOvabpT8+cMoVINrIVd1UTwKi7h5WthKID72drCt2lHG1pzQnPK6DkzjTbGlul/19Lm1d8DjMAg7GMXAEaa7dbWIt4LrZCNCv/0oZ0XQlxWxl1INgKEuOIsLjf4geafwqiEGtZdcZFFjPIplt test@example.com"
    instance_count       = 3
    min_instances        = 2
    max_instances        = 10
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.main.instances == 3
    error_message = "VMSS instance count should reflect the custom variable"
  }

  assert {
    condition     = azurerm_monitor_autoscale_setting.main.profile[0].capacity[0].minimum == 2
    error_message = "Autoscale minimum should reflect the custom variable"
  }

  assert {
    condition     = azurerm_monitor_autoscale_setting.main.profile[0].capacity[0].maximum == 10
    error_message = "Autoscale maximum should reflect the custom variable"
  }
}

# ---------------------------------------------------------------
# Test 6: NSG has HTTP and SSH rules
# ---------------------------------------------------------------
run "nsg_rules" {
  command = plan

  variables {
    subscription_id      = "00000000-0000-0000-0000-000000000001"
    admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDY5O6Vlecaw4jVcv15DNFm5VJYtWcjKPpentQHWNcuFCUl/7TAR+3B418mWGZhgDbExH+ipVyq+Bz9hS5wugYjSsaiMPa5X2wjKSCMOwUWnluzUgSFnHhyj45NWFI0S7atbU9sqGE5tqXEh1tMqkIkp1tWJexKMd4Q8M4nCJVMOtcG2CWuh7BUdJLPcMzOaYGgSNxaOvabpT8+cMoVINrIVd1UTwKi7h5WthKID72drCt2lHG1pzQnPK6DkzjTbGlul/19Lm1d8DjMAg7GMXAEaa7dbWIt4LrZCNCv/0oZ0XQlxWxl1INgKEuOIsLjf4geafwqiEGtZdcZFFjPIplt test@example.com"
  }

  assert {
    condition     = azurerm_network_security_group.vmss.name == "az204-vmss-nsg"
    error_message = "VMSS NSG name should use project_name prefix"
  }

  assert {
    condition     = length(azurerm_network_security_group.vmss.security_rule) == 2
    error_message = "VMSS NSG should have 2 security rules (HTTP + SSH)"
  }
}