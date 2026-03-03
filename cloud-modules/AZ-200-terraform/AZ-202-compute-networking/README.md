# AZ-202: Compute & Networking

**Course**: AZ-200 Azure with Terraform  
**Module**: AZ-202  
**Duration**: 2 hours  
**Prerequisites**: AZ-201 (Setup & Authentication)  
**Difficulty**: Intermediate

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Virtual Networks](#virtual-networks)
4. [Subnets and NSGs](#subnets-and-nsgs)
5. [Virtual Machines](#virtual-machines)
6. [Load Balancers](#load-balancers)
7. [Public IPs and DNS](#public-ips-and-dns)
8. [Best Practices](#best-practices)
9. [Hands-On Labs](#hands-on-labs)
10. [Troubleshooting](#troubleshooting)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course teaches you how to build Azure networking infrastructure and deploy Virtual Machines using Terraform. You'll create Virtual Networks, subnets, Network Security Groups, and VMs following Azure best practices.

### What You'll Build

By the end of this course, you'll be able to:
- Design and implement Azure Virtual Network architecture
- Create subnets with Network Security Groups
- Deploy Azure Virtual Machines
- Configure load balancers for high availability
- Manage public IPs and DNS

### Course Structure

```
AZ-202-compute-networking/
├── README.md                          # This file
└── example/
    ├── main.tf                        # Main configuration
    ├── vnet.tf                        # Virtual network
    ├── vm.tf                          # Virtual machines
    ├── nsg.tf                         # Network security groups
    ├── lb.tf                          # Load balancer
    ├── variables.tf                   # Input variables
    ├── outputs.tf                     # Output values
    └── versions.tf                    # Version constraints
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Design VNet Architecture**
   - Create Virtual Networks with CIDR blocks
   - Plan subnet layout
   - Configure peering

2. **Implement NSGs**
   - Create Network Security Groups
   - Define inbound and outbound rules
   - Associate NSGs with subnets

3. **Deploy Virtual Machines**
   - Create Linux and Windows VMs
   - Configure VM sizes and images
   - Use cloud-init for configuration

4. **Configure Load Balancers**
   - Create Azure Load Balancers
   - Configure backend pools
   - Set up health probes

5. **Manage Networking**
   - Create and assign public IPs
   - Configure DNS labels
   - Implement network peering

---

## 🌐 Virtual Networks

### Azure Network Architecture

```
Azure Region (West Europe)
└── Virtual Network (10.0.0.0/16)
    ├── Subnet: web (10.0.1.0/24)
    │   └── NSG: web-nsg
    ├── Subnet: app (10.0.2.0/24)
    │   └── NSG: app-nsg
    └── Subnet: db (10.0.3.0/24)
        └── NSG: db-nsg
```

### Creating a Virtual Network

```hcl
# vnet.tf

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg"
  location = var.location
  
  tags = local.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = local.common_tags
}
```

### Variables

```hcl
# variables.tf
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "vnet_cidr" {
  description = "CIDR block for Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

---

## 🔀 Subnets and NSGs

### Creating Subnets

```hcl
# Web subnet
resource "azurerm_subnet" "web" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# App subnet
resource "azurerm_subnet" "app" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Database subnet
resource "azurerm_subnet" "db" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]
  
  # Delegate to Azure Database for PostgreSQL
  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}
```

### Network Security Groups

```hcl
# nsg.tf

# Web NSG
resource "azurerm_network_security_group" "web" {
  name                = "${var.project_name}-web-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  # Allow HTTP
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  # Allow HTTPS
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  # Allow SSH from specific IP
  security_rule {
    name                       = "AllowSSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_ip
    destination_address_prefix = "*"
  }
  
  tags = local.common_tags
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

# App NSG (only allow from web subnet)
resource "azurerm_network_security_group" "app" {
  name                = "${var.project_name}-app-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  security_rule {
    name                       = "AllowFromWeb"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }
  
  # Deny all other inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  tags = local.common_tags
}
```

---

## 💻 Virtual Machines

### Linux VM

```hcl
# vm.tf

# Network Interface
resource "azurerm_network_interface" "web" {
  name                = "${var.project_name}-web-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "web" {
  name                = "${var.project_name}-web-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  
  network_interface_ids = [azurerm_network_interface.web.id]
  
  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 30
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>Hello from Azure Terraform!</h1>" > /var/www/html/index.html
  EOF
  )
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = local.common_tags
}
```

### Windows VM

```hcl
resource "azurerm_windows_virtual_machine" "app" {
  name                = "${var.project_name}-app-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_D2s_v3"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  
  network_interface_ids = [azurerm_network_interface.app.id]
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
  
  tags = local.common_tags
}
```

### Multiple VMs with for_each

```hcl
variable "web_vms" {
  description = "Web VM configurations"
  type = map(object({
    size         = string
    subnet_index = number
  }))
  default = {
    web-1 = { size = "Standard_B2s", subnet_index = 0 }
    web-2 = { size = "Standard_B2s", subnet_index = 0 }
  }
}

resource "azurerm_network_interface" "web_fleet" {
  for_each = var.web_vms
  
  name                = "${var.project_name}-${each.key}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "web_fleet" {
  for_each = var.web_vms
  
  name                = "${var.project_name}-${each.key}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = each.value.size
  admin_username      = var.admin_username
  
  network_interface_ids = [azurerm_network_interface.web_fleet[each.key].id]
  
  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  
  tags = local.common_tags
}
```

---

## ⚖️ Load Balancers

### Azure Load Balancer

```hcl
# lb.tf

# Public IP for Load Balancer
resource "azurerm_public_ip" "lb" {
  name                = "${var.project_name}-lb-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = local.common_tags
}

# Load Balancer
resource "azurerm_lb" "main" {
  name                = "${var.project_name}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
  
  tags = local.common_tags
}

# Backend Pool
resource "azurerm_lb_backend_address_pool" "web" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "web-backend-pool"
}

# Associate NICs with backend pool
resource "azurerm_network_interface_backend_address_pool_association" "web" {
  for_each = var.web_vms
  
  network_interface_id    = azurerm_network_interface.web_fleet[each.key].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
}

# Health Probe
resource "azurerm_lb_probe" "http" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "http-probe"
  port            = 80
  protocol        = "Http"
  request_path    = "/"
}

# Load Balancing Rule
resource "azurerm_lb_rule" "http" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.http.id
}
```

### Application Gateway (Layer 7)

```hcl
resource "azurerm_application_gateway" "main" {
  name                = "${var.project_name}-appgw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
  
  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.appgw.id
  }
  
  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }
  
  frontend_port {
    name = "http-port"
    port = 80
  }
  
  backend_address_pool {
    name = "web-backend"
  }
  
  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }
  
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }
  
  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "web-backend"
    backend_http_settings_name = "http-settings"
    priority                   = 1
  }
}
```

---

## 🌍 Public IPs and DNS

### Public IP

```hcl
# Public IP for VM
resource "azurerm_public_ip" "web" {
  name                = "${var.project_name}-web-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.project_name}-web"
  
  tags = local.common_tags
}

# Outputs
output "web_public_ip" {
  value = azurerm_public_ip.web.ip_address
}

output "web_fqdn" {
  value = azurerm_public_ip.web.fqdn
  # e.g., myproject-web.westeurope.cloudapp.azure.com
}
```

---

## ✅ Best Practices

### 1. Use Availability Sets or Zones

```hcl
# Availability Set for VMs
resource "azurerm_availability_set" "web" {
  name                         = "${var.project_name}-web-avset"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
}

# Or use Availability Zones
resource "azurerm_linux_virtual_machine" "web" {
  zone = "1"  # Deploy to zone 1
  # ...
}
```

### 2. Use Premium Storage for Production

```hcl
os_disk {
  storage_account_type = "Premium_LRS"  # ✅ Production
  # storage_account_type = "Standard_LRS"  # ❌ Dev only
}
```

### 3. Enable Boot Diagnostics

```hcl
resource "azurerm_linux_virtual_machine" "web" {
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diag.primary_blob_endpoint
  }
}
```

### 4. Use Managed Disks

```hcl
# ✅ Always use managed disks (default in newer provider versions)
os_disk {
  storage_account_type = "Premium_LRS"
  # Managed disk is the default
}
```

### 5. NSG Rule Priority

```
100-199: Allow critical traffic
200-299: Allow application traffic
300-399: Allow management traffic
4000-4096: Deny rules
```

---

## 🔬 Hands-On Labs

### Lab 1: Virtual Network (15 minutes)

**Objective**: Create a VNet with web, app, and database subnets.

**Tasks**:
1. Create resource group
2. Create VNet with 10.0.0.0/16
3. Create 3 subnets (web, app, db)
4. Create NSGs for each subnet
5. Associate NSGs with subnets
6. Verify in Azure portal

**Expected Output**:
- VNet with 3 subnets
- NSGs with appropriate rules
- Subnets associated with NSGs

---

### Lab 2: Linux Web Server (20 minutes)

**Objective**: Deploy an Nginx web server VM.

**Tasks**:
1. Create public IP
2. Create network interface
3. Deploy Ubuntu VM with Nginx
4. Configure NSG to allow HTTP
5. Access web server via public IP

**Expected Output**:
- VM running in web subnet
- Nginx serving default page
- Accessible via public IP on port 80

---

### Lab 3: Load Balanced Web Tier (25 minutes)

**Objective**: Deploy multiple VMs behind a load balancer.

**Tasks**:
1. Deploy 2 web VMs using for_each
2. Create Standard Load Balancer
3. Configure backend pool with both VMs
4. Set up health probe
5. Create load balancing rule
6. Test load balancing

**Expected Output**:
- 2 VMs in backend pool
- Load balancer distributing traffic
- Health probes passing

---

## 🐛 Troubleshooting

### Common Issues

#### 1. VM Not Accessible

**Problem**: Can't SSH to VM

**Solutions**:
```bash
# Check NSG rules
az network nsg rule list --nsg-name my-nsg --resource-group my-rg

# Check VM status
az vm show --name my-vm --resource-group my-rg --show-details

# Check public IP
az network public-ip show --name my-pip --resource-group my-rg
```

#### 2. NSG Blocking Traffic

**Problem**: Traffic blocked by NSG

**Solution**:
```bash
# Use Network Watcher to diagnose
az network watcher test-ip-flow \
  --vm my-vm \
  --direction Inbound \
  --protocol TCP \
  --local 10.0.1.4:80 \
  --remote 1.2.3.4:12345 \
  --resource-group my-rg
```

#### 3. Load Balancer Health Probe Failing

**Problem**: Backend instances marked unhealthy

**Solutions**:
- Verify web server is running on the VM
- Check NSG allows health probe traffic
- Verify health probe path returns 200

---

## 📝 Checkpoint Quiz

### Question 1: VNet vs Subnet
**What is the relationship between a VNet and a Subnet in Azure?**

A) They are the same thing  
B) A VNet contains one or more subnets  
C) A Subnet contains one or more VNets  
D) They are independent resources

<details>
<summary>Click to reveal answer</summary>

**Answer: B) A VNet contains one or more subnets**

A Virtual Network (VNet) is the top-level network container. Subnets are subdivisions of the VNet's address space, used to organize and isolate resources.
</details>

---

### Question 2: NSG Association
**Where can you associate a Network Security Group in Azure?**

A) Only to VMs  
B) Only to subnets  
C) To subnets and/or network interfaces  
D) Only to VNets

<details>
<summary>Click to reveal answer</summary>

**Answer: C) To subnets and/or network interfaces**

NSGs can be associated with subnets (affecting all resources in the subnet) and/or individual network interfaces (affecting a specific VM). Both can be applied simultaneously.
</details>

---

### Question 3: Load Balancer SKU
**Which Azure Load Balancer SKU should you use for production?**

A) Basic  
B) Standard  
C) Premium  
D) Enterprise

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Standard**

The Standard SKU supports Availability Zones, has higher SLA, supports HTTPS health probes, and is required for zone-redundant deployments. Basic is only suitable for development/testing.
</details>

---

### Question 4: VM Authentication
**What is the recommended authentication method for Linux VMs in Azure?**

A) Username and password  
B) SSH key pairs  
C) Azure AD credentials  
D) Certificate-based

<details>
<summary>Click to reveal answer</summary>

**Answer: B) SSH key pairs**

SSH key pairs are the recommended authentication method for Linux VMs. They're more secure than passwords and can be managed through Terraform using the `admin_ssh_key` block.
</details>

---

### Question 5: Managed Identity
**What is the benefit of using System Assigned Managed Identity on a VM?**

A) Better performance  
B) Allows VM to authenticate to Azure services without credentials  
C) Reduces costs  
D) Required for load balancing

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Allows VM to authenticate to Azure services without credentials**

System Assigned Managed Identity creates an identity in Azure AD for the VM. The VM can use this identity to authenticate to Azure services (Key Vault, Storage, etc.) without storing credentials.
</details>

---

### Question 6: Application Gateway vs Load Balancer
**When should you use Application Gateway instead of Azure Load Balancer?**

A) For TCP/UDP load balancing  
B) For HTTP/HTTPS with path-based routing  
C) For lower cost  
D) For higher throughput

<details>
<summary>Click to reveal answer</summary>

**Answer: B) For HTTP/HTTPS with path-based routing**

Application Gateway operates at Layer 7 (HTTP/HTTPS) and supports path-based routing, SSL termination, WAF, and cookie-based session affinity. Use Load Balancer for Layer 4 (TCP/UDP) load balancing.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [Azure VNet Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/)
- [Azure VM Documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/)
- [AzureRM Provider VM Resources](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine)

### Next Steps
- **Next Course**: [AZ-203: Security & Storage](../AZ-203-security-storage/README.md)
- **Previous Course**: [AZ-201: Setup & Authentication](../AZ-201-setup-auth/README.md)

---

*Part of the [Hashi-Training](../../../README.md) curriculum - AZ-200: Azure with Terraform*