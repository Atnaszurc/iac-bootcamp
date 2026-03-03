# AZ-204: Advanced Azure Patterns

**Course**: AZ-200 Azure with Terraform  
**Module**: AZ-204  
**Duration**: 1 hour  
**Prerequisites**: AZ-203 (Security & Storage)  
**Difficulty**: Intermediate-Advanced

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Virtual Machine Scale Sets](#virtual-machine-scale-sets)
4. [Azure SQL Database](#azure-sql-database)
5. [Azure CDN and Front Door](#azure-cdn-and-front-door)
6. [Multi-Region Deployments](#multi-region-deployments)
7. [Reusable Azure Modules](#reusable-azure-modules)
8. [Best Practices](#best-practices)
9. [Hands-On Labs](#hands-on-labs)
10. [Troubleshooting](#troubleshooting)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course covers advanced Azure patterns using Terraform. You'll learn to build auto-scaling infrastructure with VM Scale Sets, managed database services, global content delivery, and multi-region deployments following enterprise best practices.

### What You'll Build

By the end of this course, you'll be able to:
- Deploy VM Scale Sets with auto-scaling policies
- Create and manage Azure SQL databases
- Configure Azure CDN for global content delivery
- Design multi-region active-active architectures
- Build reusable Terraform modules for Azure

### Course Structure

```
AZ-204-advanced-patterns/
├── README.md                          # This file
└── example/
    ├── main.tf                        # Main configuration
    ├── vmss.tf                        # VM Scale Sets
    ├── database.tf                    # Azure SQL
    ├── cdn.tf                         # CDN / Front Door
    ├── multi-region.tf                # Multi-region setup
    ├── variables.tf                   # Input variables
    ├── outputs.tf                     # Output values
    └── versions.tf                    # Version constraints
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Deploy VM Scale Sets**
   - Create VMSS with auto-scaling
   - Configure scaling policies
   - Integrate with Load Balancer

2. **Manage Azure SQL**
   - Create SQL servers and databases
   - Configure firewall rules
   - Implement geo-replication

3. **Configure CDN**
   - Create CDN profiles and endpoints
   - Configure caching rules
   - Set up Azure Front Door

4. **Design Multi-Region Architecture**
   - Deploy to multiple regions
   - Configure Traffic Manager
   - Implement failover strategies

5. **Build Reusable Modules**
   - Create Azure-specific modules
   - Implement module composition
   - Share modules across projects

---

## 📈 Virtual Machine Scale Sets

### Basic VMSS

```hcl
# vmss.tf

resource "azurerm_linux_virtual_machine_scale_set" "web" {
  name                = "${var.project_name}-vmss"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard_B2s"
  instances           = var.vmss_initial_count
  admin_username      = var.admin_username
  
  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  
  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }
  
  network_interface {
    name    = "web-nic"
    primary = true
    
    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.web.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.web.id]
    }
  }
  
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOF
  )
  
  identity {
    type = "SystemAssigned"
  }
  
  upgrade_mode = "Rolling"
  
  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 5
    pause_time_between_batches              = "PT0S"
  }
  
  tags = local.common_tags
}
```

### Auto-Scaling Policy

```hcl
resource "azurerm_monitor_autoscale_setting" "web" {
  name                = "${var.project_name}-autoscale"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.web.id
  
  profile {
    name = "default"
    
    capacity {
      default = 2
      minimum = 2
      maximum = 10
    }
    
    # Scale out when CPU > 75%
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }
      
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
    
    # Scale in when CPU < 25%
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }
      
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }
  }
  
  # Scheduled scaling for business hours
  profile {
    name = "business-hours"
    
    capacity {
      default = 4
      minimum = 4
      maximum = 10
    }
    
    recurrence {
      timezone = "W. Europe Standard Time"
      days     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      hours    = [8]
      minutes  = [0]
    }
  }
}
```

---

## 🗃️ Azure SQL Database

### SQL Server and Database

```hcl
# database.tf

resource "azurerm_mssql_server" "main" {
  name                         = "${var.project_name}-sqlserver"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.db_admin_username
  administrator_login_password = var.db_admin_password
  
  # Enable Azure AD authentication
  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
  }
  
  tags = local.common_tags
}

resource "azurerm_mssql_database" "main" {
  name           = "${var.project_name}-db"
  server_id      = azurerm_mssql_server.main.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 32
  sku_name       = "S1"  # Standard tier
  zone_redundant = false
  
  # Enable geo-backup
  geo_backup_enabled = true
  
  # Short-term retention
  short_term_retention_policy {
    retention_days           = 7
    backup_interval_in_hours = 12
  }
  
  # Long-term retention
  long_term_retention_policy {
    weekly_retention  = "P1W"
    monthly_retention = "P1M"
    yearly_retention  = "P1Y"
    week_of_year      = 1
  }
  
  tags = local.common_tags
}

# Firewall rule for Azure services
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Firewall rule for admin IP
resource "azurerm_mssql_firewall_rule" "admin" {
  name             = "AllowAdmin"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = var.admin_ip
  end_ip_address   = var.admin_ip
}
```

### Geo-Replication

```hcl
# Secondary region SQL server
resource "azurerm_mssql_server" "secondary" {
  name                         = "${var.project_name}-sqlserver-secondary"
  resource_group_name          = azurerm_resource_group.secondary.name
  location                     = var.secondary_location
  version                      = "12.0"
  administrator_login          = var.db_admin_username
  administrator_login_password = var.db_admin_password
}

# Failover group
resource "azurerm_mssql_failover_group" "main" {
  name      = "${var.project_name}-failover-group"
  server_id = azurerm_mssql_server.main.id
  databases = [azurerm_mssql_database.main.id]
  
  partner_server {
    id = azurerm_mssql_server.secondary.id
  }
  
  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
}
```

---

## 🌐 Azure CDN and Front Door

### Azure CDN

```hcl
# cdn.tf

resource "azurerm_cdn_profile" "main" {
  name                = "${var.project_name}-cdn"
  location            = "global"
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard_Microsoft"
  
  tags = local.common_tags
}

resource "azurerm_cdn_endpoint" "web" {
  name                = "${var.project_name}-cdn-endpoint"
  profile_name        = azurerm_cdn_profile.main.name
  location            = "global"
  resource_group_name = azurerm_resource_group.main.name
  
  origin {
    name      = "web-origin"
    host_name = azurerm_public_ip.web.fqdn
  }
  
  # Cache rules
  delivery_rule {
    name  = "CacheStaticAssets"
    order = 1
    
    request_uri_condition {
      operator     = "BeginsWith"
      match_values = ["/static/"]
    }
    
    cache_expiration_action {
      behavior = "Override"
      duration = "7.00:00:00"  # 7 days
    }
  }
  
  tags = local.common_tags
}
```

### Azure Front Door (Premium)

```hcl
resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "${var.project_name}-frontdoor"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"
  
  tags = local.common_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "${var.project_name}-fd-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

resource "azurerm_cdn_frontdoor_origin_group" "web" {
  name                     = "web-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  
  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }
  
  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "primary" {
  name                          = "primary-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.web.id
  enabled                       = true
  
  host_name          = azurerm_public_ip.web.fqdn
  http_port          = 80
  https_port         = 443
  origin_host_header = azurerm_public_ip.web.fqdn
  priority           = 1
  weight             = 1000
}
```

---

## 🌍 Multi-Region Deployments

### Multi-Region Architecture

```hcl
# multi-region.tf

variable "regions" {
  description = "Azure regions to deploy to"
  type = map(object({
    location     = string
    is_primary   = bool
    vnet_cidr    = string
  }))
  default = {
    primary = {
      location   = "West Europe"
      is_primary = true
      vnet_cidr  = "10.0.0.0/16"
    }
    secondary = {
      location   = "North Europe"
      is_primary = false
      vnet_cidr  = "10.1.0.0/16"
    }
  }
}

# Create resource groups in each region
resource "azurerm_resource_group" "regions" {
  for_each = var.regions
  
  name     = "${var.project_name}-${each.key}-rg"
  location = each.value.location
  
  tags = merge(local.common_tags, {
    Region    = each.key
    IsPrimary = tostring(each.value.is_primary)
  })
}

# Create VNets in each region
resource "azurerm_virtual_network" "regions" {
  for_each = var.regions
  
  name                = "${var.project_name}-${each.key}-vnet"
  address_space       = [each.value.vnet_cidr]
  location            = azurerm_resource_group.regions[each.key].location
  resource_group_name = azurerm_resource_group.regions[each.key].name
}
```

### Traffic Manager

```hcl
resource "azurerm_traffic_manager_profile" "main" {
  name                   = "${var.project_name}-traffic-manager"
  resource_group_name    = azurerm_resource_group.main.name
  traffic_routing_method = "Performance"  # Route to lowest latency
  
  dns_config {
    relative_name = var.project_name
    ttl           = 60
  }
  
  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/health"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
  }
  
  tags = local.common_tags
}

resource "azurerm_traffic_manager_azure_endpoint" "primary" {
  name               = "primary-endpoint"
  profile_id         = azurerm_traffic_manager_profile.main.id
  target_resource_id = azurerm_public_ip.primary.id
  weight             = 100
  priority           = 1
}

resource "azurerm_traffic_manager_azure_endpoint" "secondary" {
  name               = "secondary-endpoint"
  profile_id         = azurerm_traffic_manager_profile.main.id
  target_resource_id = azurerm_public_ip.secondary.id
  weight             = 100
  priority           = 2
}
```

---

## 📦 Reusable Azure Modules

### Module Structure

```
modules/
├── azure-vm/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── azure-vnet/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
└── azure-sql/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── README.md
```

### Example: Azure VM Module

```hcl
# modules/azure-vm/variables.tf
variable "name" {
  description = "VM name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for NIC"
  type        = string
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username"
  type        = string
  default     = "azureuser"
}

variable "public_key" {
  description = "SSH public key"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
```

```hcl
# modules/azure-vm/main.tf
resource "azurerm_network_interface" "this" {
  name                = "${var.name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
  
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  
  network_interface_ids = [azurerm_network_interface.this.id]
  
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.public_key
  }
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}
```

```hcl
# modules/azure-vm/outputs.tf
output "vm_id" {
  value = azurerm_linux_virtual_machine.this.id
}

output "private_ip" {
  value = azurerm_network_interface.this.private_ip_address
}

output "principal_id" {
  value = azurerm_linux_virtual_machine.this.identity[0].principal_id
}
```

### Using the Module

```hcl
# main.tf
module "web_vm" {
  source = "./modules/azure-vm"
  
  name                = "${var.project_name}-web"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.web.id
  vm_size             = "Standard_B2s"
  admin_username      = "azureuser"
  public_key          = file("~/.ssh/id_rsa.pub")
  
  tags = local.common_tags
}

module "app_vm" {
  source = "./modules/azure-vm"
  
  name                = "${var.project_name}-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.app.id
  vm_size             = "Standard_D2s_v3"
  admin_username      = "azureuser"
  public_key          = file("~/.ssh/id_rsa.pub")
  
  tags = local.common_tags
}
```

---

## ✅ Best Practices

### 1. Use Availability Zones for VMSS

```hcl
resource "azurerm_linux_virtual_machine_scale_set" "web" {
  zones = ["1", "2", "3"]  # Deploy across all zones
  # ...
}
```

### 2. Enable Diagnostic Settings

```hcl
resource "azurerm_monitor_diagnostic_setting" "vmss" {
  name               = "${var.project_name}-diag"
  target_resource_id = azurerm_linux_virtual_machine_scale_set.web.id
  
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

### 3. Use Managed Identity for SQL Access

```hcl
# Grant VM identity access to SQL
resource "azurerm_mssql_server_active_directory_administrator" "main" {
  server_id   = azurerm_mssql_server.main.id
  login       = "AzureAD Admin"
  object_id   = azurerm_user_assigned_identity.app.principal_id
  tenant_id   = data.azurerm_client_config.current.tenant_id
}
```

### 4. Tag All Resources

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Region      = var.location
    ManagedBy   = "Terraform"
    CostCenter  = var.cost_center
  }
}
```

---

## 🔬 Hands-On Labs

### Lab 1: VM Scale Set with Auto-Scaling (20 minutes)

**Objective**: Deploy a web tier with auto-scaling.

**Tasks**:
1. Create VMSS with 2 initial instances
2. Configure CPU-based auto-scaling (scale out at 75%, in at 25%)
3. Add scheduled scaling for business hours
4. Attach to existing Load Balancer
5. Trigger scaling by generating CPU load
6. Verify instances scale out

**Expected Output**:
- VMSS with 2 instances
- Auto-scale settings configured
- Instances scale based on CPU

---

### Lab 2: Azure SQL with Geo-Replication (20 minutes)

**Objective**: Deploy SQL database with failover capability.

**Tasks**:
1. Create primary SQL server in West Europe
2. Create secondary SQL server in North Europe
3. Create database on primary
4. Configure failover group
5. Test failover to secondary
6. Verify data replication

**Expected Output**:
- SQL server in two regions
- Failover group configured
- Automatic failover enabled

---

### Lab 3: Multi-Region Deployment (20 minutes)

**Objective**: Deploy infrastructure to multiple Azure regions.

**Tasks**:
1. Define regions map variable
2. Create resource groups in each region
3. Deploy VNets in each region
4. Configure Traffic Manager
5. Add endpoints for each region
6. Test Traffic Manager routing

**Expected Output**:
- Infrastructure in 2 regions
- Traffic Manager routing traffic
- Failover working correctly

---

## 🐛 Troubleshooting

### Common Issues

#### 1. VMSS Instances Not Scaling

**Problem**: Auto-scale not triggering

**Solutions**:
```bash
# Check auto-scale history
az monitor autoscale-settings list \
  --resource-group my-rg \
  --query "[].{name:name, enabled:enabled}"

# Check VMSS metrics
az monitor metrics list \
  --resource /subscriptions/.../vmss/my-vmss \
  --metric "Percentage CPU"
```

#### 2. SQL Failover Group Not Syncing

**Problem**: Secondary database not in sync

**Solutions**:
```bash
# Check replication status
az sql failover-group show \
  --name my-failover-group \
  --resource-group my-rg \
  --server my-primary-server

# Check replication lag
az sql db replica list-links \
  --name my-db \
  --resource-group my-rg \
  --server my-primary-server
```

#### 3. Traffic Manager Not Routing

**Problem**: Traffic Manager not directing to correct endpoint

**Solutions**:
- Verify health probe is passing on both endpoints
- Check DNS TTL (may take time to propagate)
- Verify endpoint status is "Online"

---

## 📝 Checkpoint Quiz

### Question 1: VMSS vs Availability Set
**When should you use VM Scale Sets instead of Availability Sets?**

A) When you need manual scaling only  
B) When you need auto-scaling and identical VM instances  
C) When VMs need different configurations  
D) When using Windows VMs only

<details>
<summary>Click to reveal answer</summary>

**Answer: B) When you need auto-scaling and identical VM instances**

VM Scale Sets are designed for auto-scaling workloads where all instances are identical (web servers, app servers). Availability Sets are for a fixed number of VMs that may have different roles.
</details>

---

### Question 2: SQL Failover Group
**What is the purpose of an Azure SQL Failover Group?**

A) Backup the database to blob storage  
B) Provide automatic failover to a secondary region  
C) Scale the database horizontally  
D) Encrypt the database

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Provide automatic failover to a secondary region**

Failover Groups provide a single connection endpoint that automatically redirects to the secondary server during failover. This enables business continuity with minimal application changes.
</details>

---

### Question 3: Traffic Manager Routing
**Which Traffic Manager routing method sends users to the endpoint with lowest network latency?**

A) Priority  
B) Weighted  
C) Performance  
D) Geographic

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Performance**

Performance routing directs users to the endpoint with the lowest network latency from their location. This is ideal for globally distributed applications where response time is critical.
</details>

---

### Question 4: VMSS Upgrade Mode
**What does "Rolling" upgrade mode do in a VM Scale Set?**

A) Updates all instances simultaneously  
B) Updates instances in batches to maintain availability  
C) Requires manual approval for each update  
D) Only updates new instances

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Updates instances in batches to maintain availability**

Rolling upgrade mode updates instances in configurable batches (e.g., 20% at a time), ensuring a portion of instances remain available during the upgrade process.
</details>

---

### Question 5: Module Benefits
**What is the primary benefit of creating reusable Terraform modules for Azure?**

A) Faster Terraform execution  
B) Consistent, tested infrastructure patterns across projects  
C) Reduced Azure costs  
D) Automatic security compliance

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Consistent, tested infrastructure patterns across projects**

Modules encapsulate best practices and tested configurations. Teams can reuse modules across projects, ensuring consistency, reducing errors, and accelerating development.
</details>

---

### Question 6: Auto-Scale Cooldown
**Why is a cooldown period important in auto-scaling rules?**

A) To save costs by delaying scale-out  
B) To prevent rapid oscillation between scaling actions  
C) Required by Azure for compliance  
D) To allow time for VM provisioning

<details>
<summary>Click to reveal answer</summary>

**Answer: B) To prevent rapid oscillation between scaling actions**

Cooldown periods prevent "flapping" where the system rapidly scales out and in. After a scaling action, the cooldown period ensures metrics stabilize before another scaling decision is made.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [Azure VMSS Documentation](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/)
- [Azure SQL Documentation](https://docs.microsoft.com/en-us/azure/azure-sql/)
- [Azure Traffic Manager](https://docs.microsoft.com/en-us/azure/traffic-manager/)
- [AzureRM VMSS Resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine_scale_set)

### Next Steps
- **Next Module**: [MC-300: Multi-Cloud Architecture](../../MC-300-multi-cloud/README.md)
- **Previous Course**: [AZ-203: Security & Storage](../AZ-203-security-storage/README.md)
- **Module Overview**: [AZ-200: Azure with Terraform](../README.md)

---

*Part of the [Hashi-Training](../../../README.md) curriculum - AZ-200: Azure with Terraform*