# Pre and Postconditions in Terraform for Azure Resources

## Introduction

Terraform 1.2 introduced pre and postconditions, allowing for more robust validation of resources before and after their creation or modification. This lesson focuses on implementing these conditions for Azure resources.

## Table of Contents
- [Preconditions](#preconditions)
- [Postconditions](#postconditions)
- [Combined Example: Azure App Service](#combined-example-azure-app-service)
- [Best Practices](#best-practices)
- [Tasks](#tasks)
- [Task 1: Azure Storage Account](#task-1-azure-storage-account)
- [Task 2: Azure Virtual Network](#task-2-azure-virtual-network)
- [Task 3: Azure Key Vault](#task-3-azure-key-vault)
- [Task 4: Azure SQL Database](#task-4-azure-sql-database)
- [Task 5: Azure Container Registry](#task-5-azure-container-registry)
- [Bonus Task: Azure Function App](#bonus-task-azure-function-app)

## Preconditions

Preconditions are checked before Terraform attempts to create, update, or destroy a resource. They ensure that certain conditions are met before any action is taken.

### Example: Azure Storage Account

```hcl
resource "azurerm_storage_account" "example" {
    name = "examplestorage"
    resource_group_name = azurerm_resource_group.example.name
    location = azurerm_resource_group.example.location
    account_tier = "Standard"
    account_replication_type = var.replication_type
    lifecycle {
        precondition {
            condition = var.environment != "prod" || var.replication_type == "GRS"
            error_message = "Production storage accounts must use GRS replication."
        }
    }
}
```

In this example, the precondition ensures that production environments use GRS replication for storage accounts.

## Postconditions

Postconditions are checked after Terraform has successfully created or updated a resource. They verify that the resource is in the expected state after the operation.

### Example: Azure Virtual Machine
```hcl
resource "azurerm_linux_virtual_machine" "example" {
    name = "example-vm"
    resource_group_name = azurerm_resource_group.example.name
    location = azurerm_resource_group.example.location
    size = var.vm_size
    admin_username = "adminuser"
    network_interface_ids = [
        azurerm_network_interface.example.id,
    ]
    admin_ssh_key {
        username = "adminuser"
        public_key = file("~/.ssh/id_rsa.pub")
    }
    os_disk {
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts"
        version   = "latest"
    }
    lifecycle {
        postcondition {
            condition = self.os_disk[0].disk_size_gb >= 30
            error_message = "OS disk size must be at least 30GB."
        }
    }
}
```

This postcondition verifies that the created VM has an OS disk of at least 30GB.

## Combined Example: Azure App Service
```hcl
resource "azurerm_app_service" "example" {
    name = "example-app-service"
    location = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
    app_service_plan_id = azurerm_app_service_plan.example.id
    site_config {
        dotnet_framework_version = var.dotnet_version
        scm_type = "LocalGit"
    }
    lifecycle {
        precondition {
            condition = var.environment == "prod" ? var.sku_tier == "PremiumV2" : true
            error_message = "Production environment must use PremiumV2 tier."
        }
        postcondition {
            condition = self.https_only == true
            error_message = "HTTPS-only must be enabled for the App Service."
        }
    }
}
```

This example combines both pre and postconditions:
- The precondition ensures that production environments use the PremiumV2 tier.
- The postcondition verifies that HTTPS-only is enabled after creation.

## Best Practices

1. Use preconditions for validations that can be checked before resource creation or modification.
2. Use postconditions to verify the state of a resource after creation or update.
3. Provide clear and informative error messages.
4. Consider the impact on plan and apply operations when using these conditions.

## Tasks

## Task 1: Azure Storage Account

Implement pre and postconditions for an Azure Storage Account with the following requirements:

1. Precondition: Ensure that the account name is between 3 and 24 characters and contains only lowercase letters and numbers.
2. Postcondition: Verify that the created storage account has the "Access Tier" set to "Hot"

Try changing the access_tier attribute to `Cool` instead of `Hot`

### Example:
This is an example on how to solve this task:
```hcl
resource "azurerm_storage_account" "example" {
    name = var.storage_account_name
    resource_group_name = data.azurerm_resource_group.example.name
    location = data.azurerm_resource_group.example.location
    account_tier = "Standard"
    account_replication_type = "LRS"
    access_tier = "Hot"
    lifecycle {
        precondition {
        condition = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
            error_message = "Storage account name must be 3-24 characters long and contain only lowercase letters and numbers."
        }
        postcondition {
            condition = self.access_tier == "Hot"
            error_message = "The access tier for the storage account must be set to 'Hot'."
        }
    }
}
```

## Task 2: Azure Virtual Network

Create an Azure Virtual Network resource with these conditions:

1. Precondition: The address space must not overlap with the range 10.0.0.0/24.
2. Postcondition: Ensure that the created VNet has at least two subnets.

### Example:
```hcl
variable "vnet_address_space" {
    type = list(string)
}
variable "subnet_prefixes" {
    type = list(string)
}
resource "azurerm_virtual_network" "example" {
    name = "example-vnet"
    location = data.azurerm_resource_group.example.location
    resource_group_name = data.azurerm_resource_group.example.name
    address_space = var.vnet_address_space
    dynamic "subnet" {
        for_each = var.subnet_prefixes
        content {
            name = "subnet-${subnet.key + 1}"
            address_prefixes = [subnet.value]
        }
    }
    lifecycle {
        precondition {
            condition = !contains([for cidr in var.vnet_address_space : cidrsubnet(cidr, 0, 0) == "10.0.0.0/24"], true)
            error_message = "The VNet address space must not overlap with 10.0.0.0/24."
        }
        postcondition {
            condition = length(self.subnet) >= 2
            error_message = "The VNet must have at least two subnets."
        }
    }
}
```

## Task 3: Azure Key Vault

Implement conditions for an Azure Key Vault:

1. Precondition: If the environment is "prod", ensure that the SKU is "premium".
2. Postcondition: Verify that the Key Vault has soft-delete enabled.

### Example:
This is an example on how to solve this task:
```hcl
resource "azurerm_key_vault" "example" {
    name = var.key_vault_name
    location = data.azurerm_resource_group.example.location
    resource_group_name = data.azurerm_resource_group.example.name
    enabled_for_disk_encryption = true
    tenant_id = data.azurerm_client_config.current.tenant_id
    soft_delete_retention_days = 7
    purge_protection_enabled = false
    sku_name = var.environment == "prod" ? "premium" : "standard"
    lifecycle {
        precondition {
            condition = var.environment != "prod" || var.sku_name == "premium"
            error_message = "Production environment must use premium SKU for Key Vault."
        }
        postcondition {
            condition = self.soft_delete_retention_days > 0
            error_message = "Soft-delete must be enabled for the Key Vault."
        }
    }
}
```

## Task 4: Azure SQL Database

Set up an Azure SQL Database with the following conditions:

1. Precondition: The database name must not contain the word "test" in production environments.
2. Postcondition: Confirm that the created database has TDE (Transparent Data Encryption) enabled.

### Example:
```hcl
variable "environment" {
    type = string
}
variable "database_name" {
    type = string
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
    name = var.database_name
    server_id = azurerm_mssql_server.example.id
    license_type   = "LicenseIncluded"
    threat_detection_policy {
        state = "Enabled"
    }
    lifecycle {
        precondition {
            condition = var.environment != "production" || !can(regex("(?i)test", var.database_name))
            error_message = "Database name must not contain the word 'test' in production environments."
        }
        postcondition {
            condition = self.threat_detection_policy[0].state == "Enabled"
            error_message = "Transparent Data Encryption (TDE) must be enabled for the SQL Database."
        }
    }
}
```

## Task 5: Azure Container Registry

Create an Azure Container Registry with these requirements:

1. Precondition: Ensure that the SKU is either "Premium" or "Standard".
2. Postcondition: Verify that admin user is disabled for the created registry.

### Example:
This is an example on how to solve this task:
```hcl
resource "azurerm_container_registry" "example" {
    name = var.acr_name
    resource_group_name = data.azurerm_resource_group.example.name
    location = data.azurerm_resource_group.example.location
    sku = var.acr_sku
    admin_enabled = false
    lifecycle {
        precondition {
            condition = var.acr_sku == "Premium" || var.acr_sku == "Standard"
            error_message = "ACR SKU must be either Premium or Standard."
        }
        postcondition {
            condition = self.admin_enabled == false
            error_message = "Admin user must be disabled for the Container Registry."
        }
    }
}
```

## Bonus Task: Azure Function App

Implement complex pre and postconditions for an Azure Function App:

1. Precondition: 
   - Ensure that the runtime stack is compatible with the chosen OS type.
   - If the environment is "prod", require at least the "Standard" plan.

2. Postcondition:
   - Verify that HTTPS-only access is enabled.
   - Ensure that the Function App has at least one application setting defined.

### Example:
```hcl
variable "environment" {
    type = string
}
variable "function_app_name" {
    type = string
}
variable "os_type" {
    type = string
    validation {
        condition = contains(["Windows", "Linux"], var.os_type)
        error_message = "OS type must be either 'Windows' or 'Linux'."
    }
}
variable "runtime_stack" {
    type = string
}
variable "storage_account_name" {
    type = string
}
locals {
    valid_windows_stacks = ["dotnet", "node", "java", "powershell"]
    valid_linux_stacks = ["dotnet", "node", "python", "java"]
    plan_sku = var.environment == "prod" ? "S1" : "B1"
}
resource "azurerm_storage_account" "example" {
    name = var.storage_account_name
    resource_group_name = data.azurerm_resource_group.example.name
    location = data.azurerm_resource_group.example.location
    account_tier = "Standard"
    account_replication_type = "LRS"
}
resource "azurerm_service_plan" "example" {
    name = "${var.function_app_name}-plan"
    resource_group_name = data.azurerm_resource_group.example.name
    location = data.azurerm_resource_group.example.location
    os_type = var.os_type
    sku_name = local.plan_sku
}
resource "azurerm_function_app" "example" {
    name = var.function_app_name
    location = data.azurerm_resource_group.example.location
    resource_group_name = data.azurerm_resource_group.example.name
    app_service_plan_id = azurerm_service_plan.example.id
    storage_account_name = azurerm_storage_account.example.name
    storage_account_access_key = azurerm_storage_account.example.primary_access_key
    os_type = var.os_type
    version = "~4"
    app_settings = {
        "FUNCTIONS_WORKER_RUNTIME" = var.runtime_stack
    }
    https_only = true
    lifecycle {
        precondition {
            condition = (
                (var.os_type == "Windows" && contains(local.valid_windows_stacks, var.runtime_stack)) ||
                (var.os_type == "Linux" && contains(local.valid_linux_stacks, var.runtime_stack))
            )
            error_message = "The selected runtime stack is not compatible with the chosen OS type. For Windows, use one of: ${join(", ", local.valid_windows_stacks)}. For Linux, use one of: ${join(", ", local.valid_linux_stacks)}."
        }
        precondition {
            condition = var.environment != "prod" || can(regex("^(S|P)", azurerm_service_plan.example.sku_name))
            error_message = "Production environment requires at least a Standard (S1) plan. Current plan: ${azurerm_service_plan.example.sku_name}"
        }
        postcondition {
            condition = self.https_only
            error_message = "HTTPS-only access must be enabled for the Function App."
        }
        postcondition {
            condition = length(self.app_settings) > 0
            error_message = "At least one application setting must be defined for the Function App."
        }
    }
}
```

Remember to use appropriate error messages that clearly explain why a condition failed and what the correct configuration should be.