# AZ-201: Azure Setup & Authentication

**Course**: AZ-200 Azure with Terraform  
**Module**: AZ-201  
**Duration**: 1 hour  
**Prerequisites**: TF-100 series (Terraform Fundamentals)  
**Difficulty**: Intermediate

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Azure Account Setup](#azure-account-setup)
4. [Azure CLI Installation](#azure-cli-installation)
5. [Service Principal for Terraform](#service-principal-for-terraform)
6. [Terraform Azure Provider](#terraform-azure-provider)
7. [Authentication Methods](#authentication-methods)
8. [Remote State with Azure Storage](#remote-state-with-azure-storage)
9. [Best Practices](#best-practices)
10. [Hands-On Labs](#hands-on-labs)
11. [Troubleshooting](#troubleshooting)
12. [Checkpoint Quiz](#checkpoint-quiz)
13. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course teaches you how to set up Azure access for Terraform. You'll learn to configure the Azure CLI, create Service Principals with appropriate permissions, and configure the Terraform AzureRM provider using multiple authentication methods.

### What You'll Build

By the end of this course, you'll be able to:
- Set up an Azure subscription for Terraform use
- Install and configure the Azure CLI
- Create Service Principals with RBAC permissions
- Configure the Terraform AzureRM provider
- Store Terraform state in Azure Storage

### Course Structure

```
AZ-201-setup-auth/
├── README.md                          # This file
└── example/
    ├── provider.tf                    # Azure provider configuration
    ├── variables.tf                   # Input variables
    └── versions.tf                    # Version constraints
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Set Up Azure Account**
   - Navigate Azure portal
   - Understand subscriptions and tenants
   - Enable required resource providers

2. **Configure Azure CLI**
   - Install Azure CLI
   - Authenticate and manage profiles
   - Use multiple subscriptions

3. **Create Service Principals**
   - Create SP for Terraform
   - Assign RBAC roles
   - Manage credentials securely

4. **Configure Terraform Provider**
   - Write AzureRM provider configuration
   - Use environment variables
   - Configure multiple subscriptions

5. **Set Up Remote State**
   - Create Azure Storage Account
   - Configure azurerm backend
   - Enable state locking

---

## 🔑 Azure Account Setup

### Azure Subscription Structure

```
Azure Active Directory (Tenant)
└── Management Group
    └── Subscription
        └── Resource Group
            └── Resources (VMs, Storage, etc.)
```

### Azure Free Account

Azure offers a free account with:
- **$200 credit** for 30 days
- **12 months free** services (B1s VM, 5GB storage, etc.)
- **Always free** services (Azure Functions, Cosmos DB 1000 RU/s)

> ⚠️ **Cost Warning**: Set up cost alerts in Azure Cost Management to avoid unexpected charges.

### Setting Up Cost Alerts

```bash
# Create budget alert via Azure CLI
az consumption budget create \
  --budget-name "MonthlyBudget" \
  --amount 50 \
  --time-grain Monthly \
  --start-date 2024-01-01 \
  --end-date 2025-01-01 \
  --resource-group myResourceGroup
```

### Enable Resource Providers

```bash
# Register required providers
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.KeyVault

# Check registration status
az provider show --namespace Microsoft.Compute --query registrationState
```

---

## 💻 Azure CLI Installation

### Install Azure CLI

#### Linux
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### macOS
```bash
brew update && brew install azure-cli
```

#### Windows
```powershell
# Using winget
winget install Microsoft.AzureCLI

# Or download MSI from:
# https://aka.ms/installazurecliwindows
```

### Verify Installation
```bash
az --version
# azure-cli 2.x.x
```

### Authenticate with Azure CLI

```bash
# Interactive login
az login

# Login with specific tenant
az login --tenant TENANT_ID

# Login with service principal
az login --service-principal \
  --username APP_ID \
  --password PASSWORD \
  --tenant TENANT_ID
```

### Manage Subscriptions

```bash
# List subscriptions
az account list --output table

# Set default subscription
az account set --subscription "My Subscription"

# Show current subscription
az account show
```

---

## 👤 Service Principal for Terraform

### What is a Service Principal?

A Service Principal is an identity for applications (like Terraform) to access Azure resources. It's the Azure equivalent of an AWS IAM user for applications.

### Creating a Service Principal

#### Method 1: Azure CLI (Recommended)

```bash
# Create SP with Contributor role on subscription
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/SUBSCRIPTION_ID \
  --output json

# Output:
# {
#   "appId": "00000000-0000-0000-0000-000000000000",
#   "displayName": "terraform-sp",
#   "password": "GENERATED_PASSWORD",
#   "tenant": "00000000-0000-0000-0000-000000000000"
# }
```

#### Method 2: Terraform (for bootstrapping)

```hcl
# Create SP via Terraform (requires AzureAD provider)
resource "azuread_application" "terraform" {
  display_name = "terraform-app"
}

resource "azuread_service_principal" "terraform" {
  client_id = azuread_application.terraform.client_id
}

resource "azuread_service_principal_password" "terraform" {
  service_principal_id = azuread_service_principal.terraform.id
}
```

### RBAC Roles for Terraform

| Role | Permissions | Use Case |
|------|-------------|----------|
| `Owner` | Full access + RBAC | Not recommended |
| `Contributor` | Full resource access | Most Terraform use cases |
| `Reader` | Read-only | Audit/reporting |
| Custom | Specific permissions | Least privilege |

### Custom Role for Terraform

```bash
# Create custom role with minimal permissions
az role definition create --role-definition '{
  "Name": "TerraformRole",
  "Description": "Minimal permissions for Terraform",
  "Actions": [
    "Microsoft.Compute/*",
    "Microsoft.Network/*",
    "Microsoft.Storage/*",
    "Microsoft.Resources/*"
  ],
  "NotActions": [],
  "AssignableScopes": ["/subscriptions/SUBSCRIPTION_ID"]
}'
```

---

## ⚙️ Terraform Azure Provider

### Basic Provider Configuration

```hcl
# versions.tf
terraform {
  required_version = ">= 1.14"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# provider.tf
provider "azurerm" {
  features {}
  
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
```

### Provider Features Block

```hcl
provider "azurerm" {
  features {
    # Key Vault: don't purge on destroy
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    
    # Resource Group: prevent deletion if not empty
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    
    # Virtual Machine: delete OS disk on destroy
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
    }
  }
}
```

### Variables for Provider

```hcl
# variables.tf
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
  
  validation {
    condition = contains([
      "West Europe", "North Europe", "East US", "East US 2",
      "West US", "West US 2", "Southeast Asia", "Australia East"
    ], var.location)
    error_message = "Must be a valid Azure region."
  }
}
```

### Multiple Subscription Configuration

```hcl
# Primary subscription
provider "azurerm" {
  features {}
  subscription_id = var.primary_subscription_id
  alias           = "primary"
}

# Secondary subscription
provider "azurerm" {
  features {}
  subscription_id = var.secondary_subscription_id
  alias           = "secondary"
}

# Use specific provider
resource "azurerm_resource_group" "primary" {
  provider = azurerm.primary
  name     = "primary-rg"
  location = "West Europe"
}
```

---

## 🔐 Authentication Methods

### Method 1: Environment Variables (Recommended for CI/CD)

```bash
# Set credentials as environment variables
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="YOUR_CLIENT_SECRET"
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"

# Run Terraform
terraform plan
```

### Method 2: Azure CLI (Local Development)

```hcl
# Use Azure CLI credentials (no explicit config needed)
provider "azurerm" {
  features {}
  # Automatically uses 'az login' credentials
}
```

```bash
# Login first
az login
az account set --subscription "My Subscription"

# Then run Terraform
terraform plan
```

### Method 3: Managed Identity (Best for Azure VMs/ACI)

```hcl
provider "azurerm" {
  features {}
  use_msi = true
  # Automatically uses the VM's managed identity
}
```

### Method 4: Client Certificate

```hcl
provider "azurerm" {
  features {}
  
  subscription_id             = var.subscription_id
  tenant_id                   = var.tenant_id
  client_id                   = var.client_id
  client_certificate_path     = var.certificate_path
  client_certificate_password = var.certificate_password
}
```

### Authentication Priority

Terraform AzureRM checks in this order:
1. Environment variables (`ARM_*`)
2. Azure CLI credentials
3. Managed Identity
4. Provider block configuration

---

## 🗄️ Remote State with Azure Storage

### Create Storage Account for State

```hcl
# bootstrap/main.tf - Run once to create state storage

resource "azurerm_resource_group" "tfstate" {
  name     = "terraform-state-rg"
  location = "West Europe"
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstate${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  blob_properties {
    versioning_enabled = true
  }
  
  tags = {
    ManagedBy = "Terraform"
    Purpose   = "TerraformState"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
```

### Configure Backend

```hcl
# versions.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate12345678"
    container_name       = "tfstate"
    key                  = "prod/terraform.tfstate"
  }
}
```

### Backend with Variables (partial config)

```bash
# terraform.backend.hcl
resource_group_name  = "terraform-state-rg"
storage_account_name = "tfstate12345678"
container_name       = "tfstate"
key                  = "prod/terraform.tfstate"
```

```bash
terraform init -backend-config=terraform.backend.hcl
```

---

## ✅ Best Practices

### 1. Never Hardcode Credentials

❌ **NEVER DO THIS**:
```hcl
provider "azurerm" {
  features {}
  client_id     = "00000000-0000-0000-0000-000000000000"
  client_secret = "my-secret-password"
}
```

✅ **DO THIS INSTEAD**:
```bash
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
```

### 2. Use Least Privilege

```bash
# Create SP with minimal permissions
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role "Contributor" \
  --scopes /subscriptions/SUB_ID/resourceGroups/my-rg
```

### 3. Separate State per Environment

```
tfstate/
├── dev/terraform.tfstate
├── staging/terraform.tfstate
└── prod/terraform.tfstate
```

### 4. Enable Storage Account Security

```hcl
resource "azurerm_storage_account" "tfstate" {
  # ...
  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = true
  
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }
}
```

### 5. Tag Everything

```hcl
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    CostCenter  = var.cost_center
  }
}
```

---

## 🔬 Hands-On Labs

### Lab 1: Azure CLI Setup (15 minutes)

**Objective**: Install and configure the Azure CLI for Terraform use.

**Tasks**:
1. Install Azure CLI
2. Login with `az login`
3. List available subscriptions
4. Set the correct subscription
5. Verify with `az account show`
6. Create a Service Principal

**Expected Output**:
```json
{
  "appId": "...",
  "displayName": "terraform-sp",
  "password": "...",
  "tenant": "..."
}
```

---

### Lab 2: Provider Configuration (15 minutes)

**Objective**: Create a Terraform configuration with proper Azure provider setup.

**Tasks**:
1. Create `versions.tf` with version constraints
2. Create `provider.tf` with AzureRM provider
3. Set environment variables for authentication
4. Run `terraform init`
5. Run `terraform validate`
6. Create a resource group to test

**Expected Output**:
- Successful `terraform init`
- Resource group created in Azure portal

---

### Lab 3: Remote State Setup (20 minutes)

**Objective**: Configure Azure Storage backend for Terraform state.

**Tasks**:
1. Create resource group for state storage
2. Create Storage Account with versioning
3. Create blob container
4. Configure azurerm backend
5. Run `terraform init` to migrate state
6. Verify state in Azure portal

**Expected Output**:
- Storage Account created
- State file visible in blob container
- `terraform state list` works with remote state

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Authentication Failed

**Problem**: `AuthorizationFailed: The client does not have authorization`

**Solutions**:
```bash
# Check current identity
az account show

# Check SP permissions
az role assignment list --assignee APP_ID

# Re-login
az login
```

#### 2. Subscription Not Found

**Problem**: `SubscriptionNotFound: The subscription could not be found`

**Solution**:
```bash
# List subscriptions
az account list

# Set correct subscription
az account set --subscription "SUBSCRIPTION_ID"
```

#### 3. Resource Provider Not Registered

**Problem**: `MissingSubscriptionRegistration: The subscription is not registered to use namespace 'Microsoft.Compute'`

**Solution**:
```bash
az provider register --namespace Microsoft.Compute
az provider show --namespace Microsoft.Compute --query registrationState
```

#### 4. Backend State Lock

**Problem**: `Error acquiring the state lock`

**Solution**:
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

---

## 📝 Checkpoint Quiz

### Question 1: Service Principal
**What is an Azure Service Principal?**

A) A type of Azure VM  
B) An identity for applications to access Azure resources  
C) A type of storage account  
D) An Azure region

<details>
<summary>Click to reveal answer</summary>

**Answer: B) An identity for applications to access Azure resources**

A Service Principal is an application identity in Azure Active Directory that allows applications like Terraform to authenticate and access Azure resources programmatically.
</details>

---

### Question 2: Authentication Method
**What is the recommended authentication method for CI/CD pipelines?**

A) Azure CLI credentials  
B) Hardcoded credentials in provider block  
C) Environment variables (ARM_*)  
D) Managed Identity

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Environment variables (ARM_*)**

Environment variables (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, etc.) are the recommended approach for CI/CD as they can be injected securely by the CI/CD system.
</details>

---

### Question 3: Features Block
**What is the purpose of the `features {}` block in the AzureRM provider?**

A) It's optional and has no effect  
B) Required block that configures provider behavior  
C) Enables Azure preview features  
D) Configures authentication

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Required block that configures provider behavior**

The `features {}` block is required in the AzureRM provider. It can be empty or contain configuration for how the provider handles resource lifecycle events (e.g., Key Vault soft delete behavior).
</details>

---

### Question 4: Remote State
**Why use Azure Storage for Terraform state?**

A) It's faster than local state  
B) Enables team collaboration with state locking  
C) Required by Azure  
D) Reduces costs

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Enables team collaboration with state locking**

Azure Storage backend enables multiple team members to work safely with the same infrastructure. Azure Blob Storage provides automatic state locking to prevent concurrent modifications.
</details>

---

### Question 5: RBAC Role
**Which RBAC role is typically used for Terraform Service Principals?**

A) Owner  
B) Reader  
C) Contributor  
D) Global Administrator

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Contributor**

The Contributor role allows creating, updating, and deleting resources but doesn't allow managing RBAC assignments. It's the most common role for Terraform Service Principals.
</details>

---

### Question 6: Provider Version
**What does `version = "~> 4.0"` mean for the AzureRM provider?**

A) Exactly version 3.0  
B) Any version >= 3.0  
C) Version 3.x (3.0 and above, but not 4.0)  
D) Version 3.0 only

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Version 3.x (3.0 and above, but not 4.0)**

The `~>` pessimistic constraint operator allows minor and patch updates but not major version updates. `~> 4.0` allows 4.0, 4.1, 4.99 but not 5.0. The AzureRM provider is currently on version 4.x — see the [Version 4.0 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide) for breaking changes from 3.x.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [AzureRM Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure RBAC Documentation](https://docs.microsoft.com/en-us/azure/role-based-access-control/)

### Tools
- [Azure Managed Identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)
- [Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/) - For secrets management

### Next Steps
- **Next Course**: [AZ-202: Compute & Networking](../AZ-202-compute-networking/README.md)
- **Related**: [TF-104: State Management](../../../TF-100-fundamentals/TF-104-state-cli/README.md)

---

*Part of the [Hashi-Training](../../../README.md) curriculum - AZ-200: Azure with Terraform*