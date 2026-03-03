# Check Blocks with Assertions

## Introduction

Terraform 1.5 introduced Check blocks with Assertions, allowing for custom validations outside the usual resource lifecycle. These checks run at the end of plan and apply stages, providing an additional layer of verification for your infrastructure.

## Table of Contents
- [Basic Structure](#basic-structure)
- [Example: Checking Azure Storage Account Encryption](#example-checking-azure-storage-account-encryption)
- [Example: Verifying Azure Virtual Network Peering](#example-verifying-azure-virtual-network-peering)
- [Example: Checking Azure Key Vault Access Policy](#example-checking-azure-key-vault-access-policy)
- [Best Practices](#best-practices)
- [Tasks](#tasks)
- [Task 1: Azure App Service Plan Tier Verification](#task-1-azure-app-service-plan-tier-verification)
- [Task 2: Azure SQL Database Backup Retention](#task-2-azure-sql-database-backup-retention)
- [Task 3: Azure Virtual Network Subnet Configuration](#task-3-azure-virtual-network-subnet-configuration)
- [Task 4: Azure Kubernetes Service (AKS) Node Pool Verification](#task-4-azure-kubernetes-service-aks-node-pool-verification)
- [Task 5: Azure Front Door WAF Policy](#task-5-azure-front-door-waf-policy)
- [Bonus Task: Azure Monitor Alert Rule](#bonus-task-azure-monitor-alert-rule)

## Basic Structure

A Check block in Terraform follows this structure:
```hcl
check "name_of_check" {
    assert {
        condition = <boolean_expression>
        error_message = "Error message if condition is false"
    }   
}
```


## Example: Checking Azure Storage Account Encryption
```hcl
data "azurerm_storage_account" "example" {
    name = azurerm_storage_account.example.name
    resource_group_name = azurerm_resource_group.example.name
}
check "storage_encryption" {
    assert {
        condition = data.azurerm_storage_account.example.infrastructure_encryption_enabled
        error_message = "Infrastructure encryption must be enabled on the storage account."
    }
}
```

This check ensures that infrastructure encryption is enabled on the storage account after it's created.

## Example: Verifying Azure Virtual Network Peering

```hcl
data "azurerm_virtual_network" "vnet1" {
    name = azurerm_virtual_network.vnet1.name
    resource_group_name = azurerm_resource_group.example.name
}
data "azurerm_virtual_network" "vnet2" {
    name = azurerm_virtual_network.vnet2.name
    resource_group_name = azurerm_resource_group.example.name
}
check "vnet_peering" {
    assert {
        condition = length(data.azurerm_virtual_network.vnet1.vnet_peerings) > 0 && length(data.azurerm_virtual_network.vnet2.vnet_peerings) > 0
        error_message = "Virtual network peering should be established between vnet1 and vnet2."
    }
}
```

This check verifies that peering is established between two virtual networks.

## Example: Checking Azure Key Vault Access Policy
```hcl
data "azurerm_client_config" "current" {}
check "key_vault_access" {
    assert {
        condition = contains([
        for policy in azurerm_key_vault.example.access_policy : policy.object_id
        ], data.azurerm_client_config.current.object_id)
        error_message = "Current user must have an access policy in the Key Vault."
    }
}
```


This check ensures that the current user has an access policy in the created Key Vault.

## Best Practices

1. Use Check blocks for validations that span multiple resources or require complex logic.
2. Provide clear and informative error messages.
3. Consider using data sources to fetch the latest state of resources for accurate checks.
4. Group related assertions within a single Check block.

## Tasks

## Task 1: Azure App Service Plan Tier Verification

Create a Check block that verifies the tier of an Azure App Service Plan:

- If the environment is "production", ensure the App Service Plan is using at least a "PremiumV2" tier.
- For non-production environments, ensure it's at least "Standard" tier.

### Example:
```hcl
variable "environment" {
    type = string
    default = "development"
}
resource "azurerm_service_plan" "example" {
    name = "example-app-service-plan"
    resource_group_name = data.azurerm_resource_group.example.name
    location = data.azurerm_resource_group.example.location
    os_type = "Windows"
    sku_name = var.environment == "production" ? "P1v2" : "S1"
}
check "app_service_plan_tier" {
    assert {
        condition = var.environment == "production" ? contains(["P1v2", "P2v2", "P3v2"], azurerm_service_plan.example.sku_name) : startswith(azurerm_service_plan.example.sku_name, "S")
        error_message = "App Service Plan must use at least PremiumV2 tier for production, and at least Standard tier for non-production environments."
    }
}
```

## Task 2: Azure SQL Database Backup Retention

Implement a Check block that validates the backup retention policy of an Azure SQL Database:

- For production databases, ensure the retention period is at least 35 days.
- For non-production databases, ensure it's at least 7 days.

### Example:
```hcl
variable "environment" {
    type = string
    validation {
        condition = contains(["production", "development", "staging"], var.environment)
        error_message = "Environment must be 'production', 'development', or 'staging'."
    }
}
resource "azurerm_mssql_server" "example" {
    name = "example-sqlserver"
    resource_group_name = data.azurerm_resource_group.example.name
    location = data.azurerm_resource_group.example.location
    version = "12.0"
    administrator_login = "sqladmin"
    administrator_login_password = "P@ssw0rd1234!"
}
resource "azurerm_mssql_database" "example" {
    name = "example-database"
    server_id = azurerm_mssql_server.example.id
    license_type   = "LicenseIncluded"
    short_term_retention_policy {
        retention_days = var.environment == "production" ? 35 : 7
    }
}
check "sql_database_backup_retention" {
    assert {
        condition = (
        var.environment == "production" && azurerm_mssql_database.example.short_term_retention_policy[0].retention_days >= 35
        ) || (
        var.environment != "production" && azurerm_mssql_database.example.short_term_retention_policy[0].retention_days >= 7
        )
        error_message = format(
            "Invalid backup retention period for %s environment. Production requires at least 35 days, non-production at least 7 days. Current setting: %d days.",
            var.environment,
            azurerm_mssql_database.example.short_term_retention_policy[0].retention_days
        )
    }
}
```

## Task 3: Azure Virtual Network Subnet Configuration

Create a Check block that verifies the configuration of subnets in an Azure Virtual Network:

- Ensure there are at least 3 subnets.
- Verify that one subnet is designated for Azure Bastion (name contains "AzureBastionSubnet").

### Example:
```hcl
resource "azurerm_virtual_network" "example" {
    name = "example-vnet"
    address_space = ["10.0.0.0/16"]
    location = data.azurerm_resource_group.example.location
    resource_group_name = data.azurerm_resource_group.example.name
    subnet {
        name = "subnet1"
        address_prefixes = ["10.0.1.0/24"]  
    }
    subnet {
        name = "subnet2"
        address_prefixes = ["10.0.2.0/24"]
    }
    subnet {
        name = "AzureBastionSubnet"
        address_prefixes = ["10.0.3.0/24"]
    }
}
check "vnet_subnet_configuration" {
    assert {
        condition = length(azurerm_virtual_network.example.subnet) >= 3
        error_message = "The virtual network must have at least 3 subnets."
    }
    assert {
        condition = anytrue([for s in azurerm_virtual_network.example.subnet : contains(["AzureBastionSubnet"], s.name)])
        error_message = "One subnet must be designated for Azure Bastion (name should contain 'AzureBastionSubnet')."
    }
}
```

## Task 4: Azure Kubernetes Service (AKS) Node Pool Verification

Implement a Check block for an AKS cluster:

- Ensure there's at least one system node pool and one user node pool.
- Verify that the system node pool has at least 3 nodes.

### Example:
```hcl
resource "azurerm_kubernetes_cluster" "example" {
    name = "example-aks"
    location = data.azurerm_resource_group.example.location
    resource_group_name = data.azurerm_resource_group.example.name
    dns_prefix = "exampleaks"
    default_node_pool {
        name = "system"
        node_count = 3
        vm_size = "Standard_DS2_v2"
        type = "VirtualMachineScaleSets"
        mode = "System"
    }
    identity {
        type = "SystemAssigned"
    }
}
resource "azurerm_kubernetes_cluster_node_pool" "user" {
    name = "user"
    kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
    vm_size = "Standard_DS2_v2"
    node_count = 2
    mode = "User"
}
check "aks_node_pool_verification" {
    assert {
        condition = (
        length([for np in azurerm_kubernetes_cluster.example.default_node_pool : np if np.mode == "System"]) > 0 &&
        length([for np in [azurerm_kubernetes_cluster_node_pool.user] : np if np.mode == "User"]) > 0
        )
        error_message = "AKS cluster must have at least one system node pool and one user node pool."
    }
    assert {
        condition = (
        [for np in azurerm_kubernetes_cluster.example.default_node_pool : np.node_count if np.mode == "System"][0] >= 3
        )
        error_message = "The system node pool must have at least 3 nodes."
    }
}
```

## Task 5: Azure Front Door WAF Policy

Create a Check block for an Azure Front Door WAF policy:

- Ensure that the policy is in "Prevention" mode for production environments.
- Verify that at least one custom rule is configured.

### Example:
```hcl
variable "environment" {
    type = string
    default = "development"
}
resource "azurerm_frontdoor_firewall_policy" "example" {
    name = "examplewafpolicy"
    resource_group_name = data.azurerm_resource_group.example.name
    mode = var.environment == "production" ? "Prevention" : "Detection"
    managed_rule {
        type = "DefaultRuleSet"
        version = "1.0"
    }
    custom_rule {
        name = "Rule1"
        type = "MatchRule"
        action = "Block"
        priority = 1
        match_condition {
            match_variable = "RemoteAddr"
            operator = "IPMatch"
            negation_condition = false
            match_values = ["192.168.1.0/24", "10.0.0.0/24"]
        }
    }
}
check "waf_policy_configuration" {
    assert {
        condition = var.environment != "production" || azurerm_frontdoor_firewall_policy.example.mode == "Prevention"
        error_message = "WAF policy must be in Prevention mode for production environments."
    }
    assert {
        condition = length(azurerm_frontdoor_firewall_policy.example.custom_rule) > 0
        error_message = "At least one custom rule must be configured for the WAF policy."
    }
}
```

## Bonus Task: Azure Monitor Alert Rule

Implement a complex Check block for Azure Monitor Alert Rules:

- Verify that there's at least one alert rule for each of these categories: CPU usage, memory usage, and disk space.
- Ensure that all alert rules have an action group associated with them.

### Example:
```hcl
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-vm"
  resource_group_name = data.azurerm_resource_group.example.name
  location            = data.azurerm_resource_group.example.location
  size                = "Standard_F2s_v2"
  admin_username      = "ubuntu"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]
  admin_ssh_key {
    username   = "ubuntu"
    public_key = "<your-public-ssh-key>"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
resource "azurerm_monitor_action_group" "example" {
    name = "example-actiongroup"
    resource_group_name = data.azurerm_resource_group.example.name
    short_name = "exampleag"
    email_receiver {
        name = "sendtoadmin"
        email_address = "admin@example.com"
}
}
resource "azurerm_monitor_metric_alert" "cpu_alert" {
    name = "example-cpu-alert"
    resource_group_name = data.azurerm_resource_group.example.name
    scopes = [azurerm_linux_virtual_machine.example.id]
    criteria {
        metric_namespace = "Microsoft.Compute/virtualMachines"
        metric_name = "Percentage CPU"
        aggregation = "Average"
        operator = "GreaterThan"
        threshold = 80
    }
    action {
        action_group_id = azurerm_monitor_action_group.example.id
    }
}
resource "azurerm_monitor_metric_alert" "memory_alert" {
    name = "examplememoryalert"
    resource_group_name = data.azurerm_resource_group.example.name
    scopes = [azurerm_linux_virtual_machine.example.id]
    criteria {
        metric_namespace = "Microsoft.Compute/virtualMachines"
        metric_name = "Available Memory Bytes"
        aggregation = "Average"
        operator = "LessThan"
        threshold = 1073741824 # 1 GB in bytes
    }
    action {
        action_group_id = azurerm_monitor_action_group.example.id
    }
}
resource "azurerm_monitor_metric_alert" "disk_alert" {
    name = "example-disk-alert"
    resource_group_name = data.azurerm_resource_group.example.name
    scopes = [azurerm_linux_virtual_machine.example.id]
    criteria {
        metric_namespace = "Microsoft.Compute/virtualMachines"
        metric_name = "Disk Read Bytes"
        aggregation = "Total"
        operator = "GreaterThan"
        threshold = 5000000000 # 5 GB in bytes
    }
    action {
        action_group_id = azurerm_monitor_action_group.example.id
    }
}
check "monitor_alert_rules" {
    assert {
        condition = length([
        for alert in [
        azurerm_monitor_metric_alert.cpu_alert,
        azurerm_monitor_metric_alert.memory_alert,
            azurerm_monitor_metric_alert.disk_alert
        ] : alert if contains(["Percentage CPU", "Available Memory Bytes", "Disk Read Bytes"], alert.criteria[0].metric_name)
        ]) == 3
        error_message = "There must be at least one alert rule for each category: CPU usage, memory usage, and disk space."
    }
    assert {
        condition = length([
            for alert in [
                azurerm_monitor_metric_alert.cpu_alert,
                azurerm_monitor_metric_alert.memory_alert,
                azurerm_monitor_metric_alert.disk_alert
            ] : alert if length(alert.action) > 0
        ]) == 3
        error_message = "All alert rules must have an action group associated with them."
    }
}
```
Remember to use appropriate error messages that clearly explain why a check failed and what the correct configuration should be.