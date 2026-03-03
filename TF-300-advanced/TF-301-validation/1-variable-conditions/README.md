# Variable Conditions in Terraform 1.14+

## Introduction
terraform 1.14 introduced enhanced input variable validation, allowing for more complex validation rules and cross-variable references. This lesson covers how to implement these validations using the Azure provider.

## Table of Contents
- [Basic Variable Validation](#basic-variable-validation)
- [Multiple Conditions Example](#multiple-conditions-example)
- [Cross-Variable Validation](#cross-variable-validation)
- [Best Practices](#best-practices)
- [Task 1: Virtual Machine Name Validation](#task-1-virtual-machine-name-validation)
- [Task 2: Storage Account Validation](#task-2-storage-account-validation)
- [Task 3: App Service Plan Validation](#task-3-app-service-plan-validation)
- [Task 4: Network Security Group Rule Validation](#task-4-network-security-group-rule-validation)
- [Task 5: Key Vault Secret Validation](#task-5-key-vault-secret-validation)
- [Bonus Task: Azure Function App Validation](#bonus-task-azure-function-app-validation)

## Basic Variable Validation

### Single Condition Example

```hcl
hcl
variable "resource_group_name" {
    type = string
    description = "Name of the Azure Resource Group"
    validation {
        condition = can(regex("^[a-zA-Z0-9-]{3,63}$", var.resource_group_name))
        error_message = "Resource group name must be 3-63 characters long and can only contain letters, numbers, and hyphens."
    }
}
```

### Multiple Conditions Example
```hcl
hcl
variable "vm_size" {
    type = string
    description = "Size of the Azure VM"
    validation {
        condition = can(regex("^Standard_", var.vm_size))
        error_message = "VM size must start with 'Standard_'."
    }
    validation {
        condition = length(var.vm_size) >= 9 && length(var.vm_size) <= 20
        error_message = "VM size must be between 9 and 20 characters long."
    }
}
``` 


## Cross-Variable Validation

### Referencing Other Variables

```hcl
variable "environment" {
    type = string
    description = "Deployment environment (dev, test, prod)"
}
variable "vm_count" {
    type = number
    description = "Number of VMs to deploy"
    validation {
        condition = var.environment == "prod" ? var.vm_count >= 2 : true
        error_message = "Production environment must have at least 2 VMs."
    }
}
```


### Complex Validation with Multiple Variables

```hcl
hcl
variable "location" {
    type = string
    description = "Azure region for deployment"
}
variable "tier" {
    type = string
    description = "Deployment tier (basic, standard, premium)"
}
variable "storage_account_name" {
    type = string
    description = "Name of the Azure Storage Account"
    validation {
        condition = (
            length(var.storage_account_name) >= 3 &&
            length(var.storage_account_name) <= 24 &&
            can(regex("^[a-z0-9]+$", var.storage_account_name)) &&
            (var.tier == "premium" ? substr(var.storage_account_name, 0, 4) == "prem" : true) &&
            (var.location == "eastus" ? can(regex("eu", var.storage_account_name)) : true)
        )
        error_message = "Invalid storage account name. It must be 3-24 characters, lowercase alphanumeric, start with 'prem' for premium tier, and contain 'eu' for East US region."
    }
}
```


## Best Practices
1. Use `can()` function to handle potential errors in regex or other functions.
2. Provide clear and informative error messages.
3. Break complex validations into multiple blocks for better readability.
4. Consider performance impact when referencing multiple variables.


## Task 1: Virtual Machine Name Validation

Create a variable for an Azure VM name with the following requirements:
- 1-15 characters long
- Alphanumeric characters only
- Must start with a letter
- Cannot end with a hyphen

### Example:
```hcl
variable "vm_name" {
  type        = string
  description = "Name of the Azure Virtual Machine"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]{0,13}[a-zA-Z0-9]$", var.vm_name))
    error_message = "VM name must be 1-15 characters long, alphanumeric, start with a letter, and not end with a hyphen."
  }
}
```

## Task 2: Storage Account Validation

Implement validations for a storage account with these criteria:
- 3-24 characters long
- Lowercase letters and numbers only
- If the `environment` variable is set to "prod", the name must start with "prod"

### Example:
```hcl
variable "environment" {
  type        = string
  description = "Deployment environment (e.g., dev, test, prod)"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the Azure Storage Account"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 characters long and contain only lowercase letters and numbers."
  }

  validation {
    condition     = var.environment == "prod" ? can(regex("^prod", var.storage_account_name)) : true
    error_message = "For production environment, storage account name must start with 'prod'."
  }
}
```



## Task 3: App Service Plan Validation

Create variables and validations for an App Service Plan:
- `sku_tier` variable: Must be one of "Free", "Shared", "Basic", "Standard", "Premium", "PremiumV2"
- `sku_size` variable: Must be a valid size for the selected tier (e.g., "F1" for Free, "S1" for Standard)
- Implement cross-variable validation to ensure the size is valid for the chosen tier

### Example:
```hcl
variable "sku_tier" {
  type        = string
  description = "The SKU tier for the App Service Plan"

  validation {
    condition     = contains(["Free", "Shared", "Basic", "Standard", "Premium", "PremiumV2"], var.sku_tier)
    error_message = "SKU tier must be one of: Free, Shared, Basic, Standard, Premium, PremiumV2."
  }
}

variable "sku_size" {
  type        = string
  description = "The SKU size for the App Service Plan"

  validation {
    condition = contains(
      flatten([
        ["F1"],
        ["D1"],
        ["B1", "B2", "B3"],
        ["S1", "S2", "S3"],
        ["P1", "P2", "P3"],
        ["P1v2", "P2v2", "P3v2"]
      ]),
      var.sku_size
    )
    error_message = "Invalid SKU size. Must be one of: F1, D1, B1, B2, B3, S1, S2, S3, P1, P2, P3, P1v2, P2v2, P3v2."
  }
}
```
 
## Task 4: Network Security Group Rule Validation

Implement validations for NSG rule properties:
- `priority` variable: Number between 100 and 4096
- `direction` variable: Must be either "Inbound" or "Outbound"
- `access` variable: Must be either "Allow" or "Deny"
- `protocol` variable: Must be "Tcp", "Udp", "Icmp", or "*"
- `source_port_range` and `destination_port_range` variables: Must be a valid port number (0-65535) or range (e.g., "80-90"), or "*"

### Example
```hcl
variable "priority" {
  type        = number
  description = "Priority of the NSG rule"
  validation {
    condition     = var.priority >= 100 && var.priority <= 4096
    error_message = "Priority must be a number between 100 and 4096."
  }
}

variable "direction" {
  type        = string
  description = "Direction of the NSG rule"
  validation {
    condition     = can(regex("^(Inbound|Outbound)$", var.direction))
    error_message = "Direction must be either 'Inbound' or 'Outbound'."
  }
}

variable "access" {
  type        = string
  description = "Access type for the NSG rule"
  validation {
    condition     = can(regex("^(Allow|Deny)$", var.access))
    error_message = "Access must be either 'Allow' or 'Deny'."
  }
}

variable "protocol" {
  type        = string
  description = "Protocol for the NSG rule"
  validation {
    condition     = can(regex("^(Tcp|Udp|Icmp|\\*)$", var.protocol))
    error_message = "Protocol must be 'Tcp', 'Udp', 'Icmp', or '*'."
  }
}

variable "source_port_range" {
  type        = string
  description = "Source port range for the NSG rule"
  validation {
    condition     = can(regex("^(\\*|([0-9]{1,5})-([0-9]{1,5})|[0-9]{1,5})$", var.source_port_range)) && (var.source_port_range == "*" || tonumber(split("-", var.source_port_range)[0]) <= 65535)
    error_message = "Source port range must be '*', a number between 0 and 65535, or a range (e.g., '80-90')."
  }
}

variable "destination_port_range" {
  type        = string
  description = "Destination port range for the NSG rule"
  validation {
    condition     = can(regex("^(\\*|([0-9]{1,5})-([0-9]{1,5})|[0-9]{1,5})$", var.destination_port_range)) && (var.destination_port_range == "*" || tonumber(split("-", var.destination_port_range)[0]) <= 65535)
    error_message = "Destination port range must be '*', a number between 0 and 65535, or a range (e.g., '80-90')."
  }
}
```

### Example with object

This is an example of how the above variable could be created as an object instead of multiple variables of type string.

```hcl
variable "nsg" {
    type = object({
        priority = number
        direction = string
        access = string
        destination_port = number
        source_port = number
    })
    validation {
      condition = var.nsg.priority >= 100 && var.nsg.priority <= 4096
      error_message = "Wrong priority"
    }
    validation {
      condition = var.nsg.destination_port == 80 && var.nsg.access == "allow" ? false : true
      error_message = "Don't allow port 80"
    }
}
```

## Task 5: Key Vault Secret Validation

Create a variable for a Key Vault secret with these validations:
- Secret name must be 1-127 characters
- Can only contain alphanumeric characters and dashes
- Secret value must be a valid base64 string
- If `environment` is "prod", require a minimum secret length of 32 characters

### Example
```hcl
variable "environment" {
  type        = string
  description = "Deployment environment (e.g., dev, test, prod)"
}

variable "secret_name" {
  type        = string
  description = "Name of the Key Vault secret"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,127}$", var.secret_name))
    error_message = "Secret name must be 1-127 characters long and can only contain alphanumeric characters and dashes."
  }
}

variable "secret_value" {
  type        = string
  description = "Value of the Key Vault secret"
  sensitive   = true

  validation {
    condition     = can(base64decode(var.secret_value))
    error_message = "Secret value must be a valid base64 encoded string."
  }

  validation {
    condition     = var.environment == "prod" ? length(var.secret_value) >= 32 : true
    error_message = "For production environment, secret value must be at least 32 characters long."
  }
}
```

## Bonus Task: Azure Function App Validation

Implement complex validations for an Azure Function App:
- `name` variable: 2-60 characters, alphanumeric and hyphens, must start and end with alphanumeric
- `os_type` variable: Must be "Windows" or "Linux"
- `runtime_stack` variable: Must be a valid runtime for the chosen OS (e.g., "dotnet", "node", "python" for both; "java" for Linux only)
- `runtime_version` variable: Must be a valid version for the chosen runtime stack
- Implement cross-variable validation to ensure compatibility between `os_type`, `runtime_stack`, and `runtime_version`

### Example
```hcl
variable "name" {
  type        = string
  description = "Name of the Azure Function App"
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,58}[a-zA-Z0-9]$", var.name))
    error_message = "Function App name must be 2-60 characters, alphanumeric and hyphens, starting and ending with alphanumeric."
  }
}

variable "os_type" {
  type        = string
  description = "Operating System type for the Function App"
  validation {
    condition     = contains(["Windows", "Linux"], var.os_type)
    error_message = "OS type must be either 'Windows' or 'Linux'."
  }
}

variable "runtime_stack" {
  type        = string
  description = "Runtime stack for the Function App"
  validation {
    condition     = contains(var.os_type == "Windows" ? ["dotnet", "node", "python"] : ["dotnet", "node", "python", "java"], var.runtime_stack)
    error_message = "Invalid runtime stack for the selected OS. Windows supports dotnet, node, and python. Linux supports dotnet, node, python, and java."
  }
}

variable "runtime_version" {
  type        = string
  description = "Version of the runtime stack"
  validation {
    condition     = (
      (var.runtime_stack == "dotnet" && contains(["3.1", "6.0"], var.runtime_version)) ||
      (var.runtime_stack == "node" && contains(["14", "16", "18"], var.runtime_version)) ||
      (var.runtime_stack == "python" && contains(["3.8", "3.9", "3.10"], var.runtime_version)) ||
      (var.runtime_stack == "java" && contains(["8", "11", "17"], var.runtime_version))
    )
    error_message = "Invalid runtime version for the selected runtime stack. Please check the supported versions for your chosen runtime."
  }
}
```

Remember to use appropriate error messages that clearly explain why a validation failed and what the correct input should be.