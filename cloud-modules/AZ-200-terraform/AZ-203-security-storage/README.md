# AZ-203: Security & Storage

**Course**: AZ-200 Azure with Terraform  
**Module**: AZ-203  
**Duration**: 2 hours  
**Prerequisites**: AZ-202 (Compute & Networking)  
**Difficulty**: Intermediate

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Azure Storage Accounts](#azure-storage-accounts)
4. [Managed Disks](#managed-disks)
5. [Azure Key Vault](#azure-key-vault)
6. [RBAC and IAM](#rbac-and-iam)
7. [Azure Active Directory](#azure-active-directory)
8. [Best Practices](#best-practices)
9. [Hands-On Labs](#hands-on-labs)
10. [Troubleshooting](#troubleshooting)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course covers Azure security and storage services managed with Terraform. You'll learn to create Storage Accounts, manage Managed Disks, configure Key Vault for secrets management, and implement Role-Based Access Control (RBAC).

### What You'll Build

By the end of this course, you'll be able to:
- Create and configure Azure Storage Accounts
- Manage Managed Disks for VMs
- Store and retrieve secrets from Azure Key Vault
- Implement RBAC for least-privilege access
- Configure Managed Identities for secure service-to-service auth

### Course Structure

```
AZ-203-security-storage/
├── README.md                          # This file
└── example/
    ├── main.tf                        # Main configuration
    ├── storage.tf                     # Storage accounts
    ├── keyvault.tf                    # Key Vault
    ├── rbac.tf                        # RBAC assignments
    ├── disks.tf                       # Managed disks
    ├── variables.tf                   # Input variables
    ├── outputs.tf                     # Output values
    └── versions.tf                    # Version constraints
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Manage Azure Storage**
   - Create Storage Accounts with appropriate tiers
   - Configure blob containers and access policies
   - Implement storage lifecycle management
   - Enable encryption and secure transfer

2. **Work with Managed Disks**
   - Create and attach data disks to VMs
   - Choose appropriate disk types
   - Implement disk encryption

3. **Use Azure Key Vault**
   - Create Key Vault instances
   - Store and retrieve secrets
   - Manage access policies
   - Integrate with VMs via Managed Identity

4. **Implement RBAC**
   - Assign built-in roles
   - Create custom roles
   - Apply least-privilege principle
   - Manage service principals

5. **Configure Managed Identities**
   - Enable System Assigned Identity
   - Create User Assigned Identity
   - Grant permissions to identities

---

## 🗄️ Azure Storage Accounts

### Storage Account Types

| Type | Use Case | Redundancy |
|------|----------|------------|
| StorageV2 | General purpose (recommended) | LRS, ZRS, GRS, GZRS |
| BlobStorage | Blob-only workloads | LRS, GRS, RA-GRS |
| BlockBlobStorage | Premium blob performance | LRS, ZRS |
| FileStorage | Azure Files premium | LRS, ZRS |

### Creating a Storage Account

```hcl
# storage.tf

resource "azurerm_storage_account" "main" {
  name                     = "${var.project_name}storage"  # Must be globally unique, 3-24 chars
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"  # Geo-redundant storage
  account_kind             = "StorageV2"
  
  # Security settings
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  # Blob properties
  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 30
    }
    
    container_delete_retention_policy {
      days = 30
    }
  }
  
  # Network rules
  network_rules {
    default_action             = "Deny"
    ip_rules                   = [var.admin_ip]
    virtual_network_subnet_ids = [azurerm_subnet.app.id]
    bypass                     = ["AzureServices"]
  }
  
  tags = local.common_tags
}
```

### Blob Containers

```hcl
# Public container (for static website assets)
resource "azurerm_storage_container" "public" {
  name                  = "public"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "blob"  # Public read access for blobs
}

# Private container (for application data)
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"  # No public access
}

# Terraform state container
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
```

### Storage Lifecycle Management

```hcl
resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id
  
  rule {
    name    = "archive-old-blobs"
    enabled = true
    
    filters {
      prefix_match = ["data/"]
      blob_types   = ["blockBlob"]
    }
    
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }
      
      snapshot {
        delete_after_days_since_creation_greater_than = 30
      }
    }
  }
}
```

### Static Website Hosting

```hcl
resource "azurerm_storage_account" "website" {
  name                     = "${var.project_name}website"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }
}

output "website_url" {
  value = azurerm_storage_account.website.primary_web_endpoint
}
```

---

## 💾 Managed Disks

### Disk Types

| Type | Use Case | Max IOPS |
|------|----------|----------|
| Standard HDD | Dev/test, infrequent access | 500 |
| Standard SSD | Web servers, lightly used apps | 6,000 |
| Premium SSD | Production, I/O intensive | 20,000 |
| Ultra Disk | Databases, high throughput | 160,000 |

### Creating and Attaching Managed Disks

```hcl
# disks.tf

# Create a data disk
resource "azurerm_managed_disk" "data" {
  name                 = "${var.project_name}-data-disk"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128
  
  # Enable encryption with platform-managed key
  encryption_settings {
    enabled = true
  }
  
  tags = local.common_tags
}

# Attach disk to VM
resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  managed_disk_id    = azurerm_managed_disk.data.id
  virtual_machine_id = azurerm_linux_virtual_machine.web.id
  lun                = 0
  caching            = "ReadWrite"
}
```

### Disk Encryption with Customer-Managed Keys

```hcl
# Create disk encryption set
resource "azurerm_disk_encryption_set" "main" {
  name                = "${var.project_name}-des"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  key_vault_key_id    = azurerm_key_vault_key.disk.id
  
  identity {
    type = "SystemAssigned"
  }
}

# Grant Key Vault access to encryption set
resource "azurerm_key_vault_access_policy" "disk_encryption" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_disk_encryption_set.main.identity[0].principal_id
  
  key_permissions = [
    "Get", "WrapKey", "UnwrapKey"
  ]
}
```

---

## 🔐 Azure Key Vault

### Creating Key Vault

```hcl
# keyvault.tf

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "${var.project_name}-kv"  # Must be globally unique
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  
  # Security settings
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
  
  # Network access
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = [var.admin_ip]
  }
  
  tags = local.common_tags
}
```

### Access Policies

```hcl
# Grant Terraform service principal access
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  
  key_permissions = [
    "Get", "List", "Create", "Delete", "Update",
    "Recover", "Purge", "GetRotationPolicy"
  ]
  
  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Purge"
  ]
  
  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Update"
  ]
}

# Grant VM Managed Identity access to secrets
resource "azurerm_key_vault_access_policy" "vm" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_virtual_machine.web.identity[0].principal_id
  
  secret_permissions = ["Get", "List"]
}
```

### Storing Secrets

```hcl
# Store a database password
resource "azurerm_key_vault_secret" "db_password" {
  name         = "database-password"
  value        = var.db_password  # Pass via TF_VAR_db_password env var
  key_vault_id = azurerm_key_vault.main.id
  
  # Set expiration
  expiration_date = "2027-01-01T00:00:00Z"
  
  tags = local.common_tags
  
  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# Store connection string
resource "azurerm_key_vault_secret" "db_connection" {
  name         = "database-connection-string"
  value        = "Server=${azurerm_mssql_server.main.fully_qualified_domain_name};Database=${var.db_name};..."
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# Read a secret (reference existing)
data "azurerm_key_vault_secret" "existing" {
  name         = "existing-secret"
  key_vault_id = azurerm_key_vault.main.id
}

output "secret_value" {
  value     = data.azurerm_key_vault_secret.existing.value
  sensitive = true
}
```

### Encryption Keys

```hcl
# Create an encryption key
resource "azurerm_key_vault_key" "main" {
  name         = "${var.project_name}-key"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048
  
  key_opts = [
    "decrypt", "encrypt", "sign",
    "unwrapKey", "verify", "wrapKey"
  ]
  
  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
  
  depends_on = [azurerm_key_vault_access_policy.terraform]
}
```

---

## 🔑 RBAC and IAM

### Built-in Role Assignments

```hcl
# rbac.tf

# Assign Storage Blob Data Contributor to a service principal
resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.web.identity[0].principal_id
}

# Assign Reader role at resource group level
resource "azurerm_role_assignment" "rg_reader" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = var.developer_object_id
}

# Assign Contributor at subscription level (use carefully)
resource "azurerm_role_assignment" "subscription_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = var.devops_object_id
}
```

### Custom Role Definition

```hcl
resource "azurerm_role_definition" "custom_vm_operator" {
  name        = "Custom VM Operator"
  scope       = azurerm_resource_group.main.id
  description = "Can start, stop, and restart VMs but not create or delete"
  
  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/deallocate/action",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read"
    ]
    not_actions = []
  }
  
  assignable_scopes = [
    azurerm_resource_group.main.id
  ]
}

resource "azurerm_role_assignment" "vm_operator" {
  scope              = azurerm_resource_group.main.id
  role_definition_id = azurerm_role_definition.custom_vm_operator.role_definition_resource_id
  principal_id       = var.operator_object_id
}
```

---

## 🆔 Azure Active Directory

### User Assigned Managed Identity

```hcl
# Create User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "app" {
  name                = "${var.project_name}-app-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# Assign to VM
resource "azurerm_linux_virtual_machine" "web" {
  # ...
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }
}

# Grant identity access to Key Vault
resource "azurerm_key_vault_access_policy" "app_identity" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app.principal_id
  
  secret_permissions = ["Get", "List"]
}

# Grant identity access to Storage
resource "azurerm_role_assignment" "app_storage" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}
```

---

## ✅ Best Practices

### 1. Storage Security

```hcl
resource "azurerm_storage_account" "secure" {
  # ✅ Always enforce HTTPS
  https_traffic_only_enabled = true
  
  # ✅ Use minimum TLS 1.2
  min_tls_version = "TLS1_2"
  
  # ✅ Disable public blob access
  allow_nested_items_to_be_public = false
  
  # ✅ Use network rules
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}
```

### 2. Key Vault Security

```hcl
resource "azurerm_key_vault" "secure" {
  # ✅ Enable purge protection
  purge_protection_enabled = true
  
  # ✅ Enable soft delete (default in newer versions)
  soft_delete_retention_days = 90
  
  # ✅ Restrict network access
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}
```

### 3. Least Privilege RBAC

```hcl
# ✅ Use specific scope (not subscription-wide)
resource "azurerm_role_assignment" "specific" {
  scope                = azurerm_storage_account.main.id  # Specific resource
  role_definition_name = "Storage Blob Data Reader"       # Minimal permissions
  principal_id         = var.app_principal_id
}

# ❌ Avoid broad permissions
# scope = "/subscriptions/${var.subscription_id}"
# role_definition_name = "Owner"
```

### 4. Never Store Secrets in Terraform State

```hcl
# ✅ Use Key Vault references
variable "db_password" {
  description = "Database password - set via TF_VAR_db_password"
  type        = string
  sensitive   = true
}

# ❌ Never hardcode secrets
# db_password = "MyPassword123!"
```

---

## 🔬 Hands-On Labs

### Lab 1: Secure Storage Account (15 minutes)

**Objective**: Create a storage account with security best practices.

**Tasks**:
1. Create storage account with HTTPS-only
2. Disable public blob access
3. Configure network rules (deny by default)
4. Create private blob container
5. Enable versioning and soft delete
6. Verify access is restricted

**Expected Output**:
- Storage account with security settings
- Private container created
- Network access restricted

---

### Lab 2: Key Vault Integration (20 minutes)

**Objective**: Store and retrieve secrets using Key Vault.

**Tasks**:
1. Create Key Vault with purge protection
2. Configure access policy for Terraform
3. Store a database password as secret
4. Create a VM with System Assigned Identity
5. Grant VM identity access to Key Vault
6. Verify VM can read the secret

**Expected Output**:
- Key Vault with secret stored
- VM with Managed Identity
- Access policy granting VM read access

---

### Lab 3: RBAC Implementation (20 minutes)

**Objective**: Implement least-privilege access with RBAC.

**Tasks**:
1. Create a User Assigned Managed Identity
2. Assign Storage Blob Data Contributor role
3. Assign Key Vault Secrets User role
4. Create custom role for VM operations
5. Assign custom role to a principal
6. Verify permissions work correctly

**Expected Output**:
- Identity with specific role assignments
- Custom role definition
- Least-privilege access implemented

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Key Vault Access Denied

**Problem**: `AuthorizationFailed` when accessing Key Vault

**Solutions**:
```bash
# Check current user's object ID
az ad signed-in-user show --query id -o tsv

# List access policies
az keyvault show --name my-kv --query properties.accessPolicies

# Add access policy
az keyvault set-policy \
  --name my-kv \
  --object-id <your-object-id> \
  --secret-permissions get list set delete
```

#### 2. Storage Account Name Already Taken

**Problem**: Storage account name must be globally unique

**Solution**:
```hcl
# Use random suffix
resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "main" {
  name = "${var.project_name}${random_string.storage_suffix.result}"
  # ...
}
```

#### 3. RBAC Propagation Delay

**Problem**: Role assignment not taking effect immediately

**Solution**:
```hcl
# Add depends_on to resources that need the role
resource "azurerm_storage_blob" "data" {
  depends_on = [azurerm_role_assignment.storage_contributor]
  # ...
}
```

---

## 📝 Checkpoint Quiz

### Question 1: Storage Redundancy
**Which storage redundancy option provides the highest durability?**

A) LRS (Locally Redundant Storage)  
B) ZRS (Zone Redundant Storage)  
C) GRS (Geo-Redundant Storage)  
D) GZRS (Geo-Zone Redundant Storage)

<details>
<summary>Click to reveal answer</summary>

**Answer: D) GZRS (Geo-Zone Redundant Storage)**

GZRS combines zone redundancy (ZRS) within the primary region with geo-replication to a secondary region, providing the highest durability (16 nines) and availability.
</details>

---

### Question 2: Key Vault Purge Protection
**What does enabling purge protection on Key Vault do?**

A) Prevents all deletions  
B) Prevents permanent deletion during soft-delete retention period  
C) Encrypts all secrets  
D) Requires MFA for access

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Prevents permanent deletion during soft-delete retention period**

Purge protection prevents the permanent deletion (purge) of a Key Vault and its objects during the soft-delete retention period. This protects against accidental or malicious permanent deletion.
</details>

---

### Question 3: RBAC Scope
**What is the correct order of RBAC scope from broadest to narrowest?**

A) Resource → Resource Group → Subscription → Management Group  
B) Management Group → Subscription → Resource Group → Resource  
C) Subscription → Management Group → Resource Group → Resource  
D) Resource Group → Subscription → Resource → Management Group

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Management Group → Subscription → Resource Group → Resource**

RBAC permissions are inherited from parent scopes. Assigning a role at Management Group level grants access to all subscriptions, resource groups, and resources within it.
</details>

---

### Question 4: Managed Identity Types
**What is the difference between System Assigned and User Assigned Managed Identity?**

A) System Assigned can be shared between resources; User Assigned cannot  
B) User Assigned can be shared between resources; System Assigned is tied to one resource  
C) They are functionally identical  
D) System Assigned supports more Azure services

<details>
<summary>Click to reveal answer</summary>

**Answer: B) User Assigned can be shared between resources; System Assigned is tied to one resource**

System Assigned identity is created with and deleted with the resource. User Assigned identity is a standalone resource that can be assigned to multiple VMs/services, making it ideal for shared identity scenarios.
</details>

---

### Question 5: Storage Network Rules
**What does setting `default_action = "Deny"` in storage network rules do?**

A) Denies all traffic including Azure services  
B) Denies all traffic except explicitly allowed IPs/VNets and bypassed services  
C) Only denies external traffic  
D) Requires encryption for all traffic

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Denies all traffic except explicitly allowed IPs/VNets and bypassed services**

With `default_action = "Deny"`, only traffic from explicitly listed IP ranges, virtual network subnets, and services listed in `bypass` (like `AzureServices`) are allowed.
</details>

---

### Question 6: Sensitive Variables
**How should you pass sensitive values like passwords to Terraform?**

A) Hardcode them in .tf files  
B) Store them in terraform.tfvars  
C) Use TF_VAR_ environment variables or a secrets manager  
D) Pass them as command-line arguments

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Use TF_VAR_ environment variables or a secrets manager**

Environment variables (`TF_VAR_db_password`) keep secrets out of files. For production, use Azure Key Vault or HashiCorp Vault to retrieve secrets dynamically. Never commit secrets to version control.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [Azure Storage Documentation](https://docs.microsoft.com/en-us/azure/storage/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)
- [Azure RBAC Documentation](https://docs.microsoft.com/en-us/azure/role-based-access-control/)
- [AzureRM Storage Account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account)
- [AzureRM Key Vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault)

### Next Steps
- **Next Course**: [AZ-204: Advanced Patterns](../AZ-204-advanced-patterns/README.md)
- **Previous Course**: [AZ-202: Compute & Networking](../AZ-202-compute-networking/README.md)

---

*Part of the [Hashi-Training](../../../README.md) curriculum - AZ-200: Azure with Terraform*