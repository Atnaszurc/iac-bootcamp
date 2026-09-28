# TF-201: Module Design & Composition

**Course Level**: 200 (Intermediate)  
**Duration**: 1.5 hours  
**Prerequisites**: TF-100 Series (Fundamentals)

---

## 📋 Overview

This course introduces Terraform modules - the fundamental building blocks for creating reusable, maintainable infrastructure code. You'll learn how to design, structure, and compose modules effectively, transforming your infrastructure code from flat configurations into organized, reusable components.

**Why Modules Matter**: Modules are to Terraform what functions are to programming - they encapsulate logic, promote reusability, and make complex systems manageable.

---

## 🎯 Learning Objectives

By the end of this course, you will be able to:

- ✅ Understand what Terraform modules are and why they're essential
- ✅ Design well-structured modules following best practices
- ✅ Create simple single-resource modules
- ✅ Build complex multi-resource modules
- ✅ Define module inputs (variables) effectively
- ✅ Expose module outputs for composition
- ✅ Compose modules together to build infrastructure
- ✅ Version modules for stability and collaboration
- ✅ Apply the Standard Module Structure
- ✅ Refactor existing code into reusable modules

---

## 📚 What Are Terraform Modules?

### Definition

A **Terraform module** is a container for multiple resources that are used together. Every Terraform configuration has at least one module, called the **root module**, which consists of the resources defined in the `.tf` files in the main working directory.

### Module Types

1. **Root Module**: Your main Terraform configuration
   - The directory where you run `terraform apply`
   - Calls child modules
   - Defines providers

2. **Child Modules**: Reusable components
   - Called by the root module or other modules
   - Encapsulate specific functionality
   - Can be local or remote

3. **Published Modules**: Shared modules
   - Terraform Registry (public)
   - Private registries
   - Git repositories
   - HTTP URLs

---

## 🏗️ Module Structure

### Standard Module Structure

Following HashiCorp's recommended structure:

```
my-module/
├── main.tf          # Primary resource definitions
├── variables.tf     # Input variable declarations
├── outputs.tf       # Output value declarations
├── versions.tf      # Provider version constraints
├── README.md        # Module documentation
├── examples/        # Usage examples
│   └── basic/
│       ├── main.tf
│       └── variables.tf
└── modules/         # Nested child modules (optional)
    └── submodule/
```

### File Purposes

**main.tf**:
- Contains the primary resource definitions
- Core logic of the module
- Data sources if needed

**variables.tf**:
- All input variable declarations
- Variable descriptions and types
- Validation rules
- Default values (when appropriate)

**outputs.tf**:
- All output value declarations
- Expose important resource attributes
- Enable module composition

**versions.tf**:
- Terraform version constraints
- Provider version constraints
- Required providers

**README.md**:
- Module purpose and description
- Usage examples
- Input/output documentation
- Requirements and dependencies

---

## 🎓 Module Design Principles

### 1. Single Responsibility

Each module should have **one clear purpose**:

✅ **Good**: `libvirt-network` module creates networks  
✅ **Good**: `libvirt-vm` module creates virtual machines  
❌ **Bad**: `infrastructure` module creates everything

### 2. Composability

Modules should work together:

```hcl
# Network module
module "network" {
  source = "./modules/network"
  name   = "app-network"
}

# VM module uses network module output
module "vm" {
  source     = "./modules/vm"
  network_name = module.network.network_name
}
```

### 3. Encapsulation

Hide complexity, expose simplicity:

```hcl
# Module hides complex networking details
module "network" {
  source = "./modules/network"
  
  # Simple inputs
  name = "my-network"
  cidr = "10.0.0.0/16"
  
  # Module handles:
  # - Network creation
  # - Subnet configuration
  # - DHCP setup
  # - DNS configuration
}
```

### 4. Flexibility

Use variables for customization:

```hcl
variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "Memory in MB"
  type        = number
  default     = 512
}
```

### 5. Documentation

Always document your modules:

```hcl
variable "network_name" {
  description = "Name of the libvirt network to create"
  type        = string
  
  validation {
    condition     = length(var.network_name) > 0
    error_message = "Network name cannot be empty"
  }
}
```

---

## 💻 Hands-On Lab 1: Simple Module

### Objective
Create a simple single-resource module for Libvirt networks.

### Duration
20 minutes

### Steps

#### 1. Create Module Directory Structure

```bash
mkdir -p modules/libvirt-network
cd modules/libvirt-network
```

#### 2. Create `main.tf`

```hcl
# modules/libvirt-network/main.tf
terraform {
  required_version = ">= 1.14"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
  }
}

locals {
  prefix_length = tonumber(split("/", var.cidr)[1])
}

resource "libvirt_network" "this" {
  name      = var.network_name
  autostart = var.autostart

  # libvirt provider 0.9.x uses nested ATTRIBUTES (forward = { ... }), not
  # blocks, so optional parts are a conditional that yields an object or null.
  # An isolated network is simply one without forward.
  forward = var.network_mode == "isolated" ? null : { mode = var.network_mode }

  domain = { name = var.domain }

  dns = { enable = var.enable_dns ? "yes" : "no" }

  ips = [
    {
      address = cidrhost(var.cidr, 1)
      prefix  = local.prefix_length
      dhcp = var.enable_dhcp ? {
        ranges = [
          {
            start = cidrhost(var.cidr, 100)
            end   = cidrhost(var.cidr, 200)
          }
        ]
      } : null
    }
  ]
}
```

> 💡 **Why no `dynamic` blocks?** In libvirt provider 0.9.x, `forward`, `dns` and `dhcp` are nested *attributes* (`dns = { ... }`), not blocks (`dns { ... }`). `dynamic` only generates blocks. For an optional attribute, use a conditional that returns either an object or `null`, as above.

#### 3. Create `variables.tf`

```hcl
# modules/libvirt-network/variables.tf
variable "network_name" {
  description = "Name of the libvirt network"
  type        = string

  validation {
    condition     = length(var.network_name) > 0 && length(var.network_name) <= 64
    error_message = "Network name must be between 1 and 64 characters"
  }
}

variable "network_mode" {
  description = "Forwarding mode: nat, route or isolated"
  type        = string
  default     = "nat"

  validation {
    condition     = contains(["nat", "route", "isolated"], var.network_mode)
    error_message = "Network mode must be one of: nat, route, isolated"
  }
}

variable "domain" {
  description = "DNS domain for the network"
  type        = string
  default     = "local"
}

variable "cidr" {
  description = "IPv4 range for the network. The host gets the first address, DHCP hands out .100-.200"
  type        = string
  default     = "10.17.3.0/24"

  validation {
    condition     = can(cidrnetmask(var.cidr))
    error_message = "cidr must be a valid IPv4 CIDR block, e.g. 10.17.3.0/24"
  }
}

variable "autostart" {
  description = "Whether to start the network automatically"
  type        = bool
  default     = true
}

variable "enable_dns" {
  description = "Enable DNS for the network"
  type        = bool
  default     = true
}

variable "enable_dhcp" {
  description = "Enable DHCP for the network"
  type        = bool
  default     = true
}
```

#### 4. Create `outputs.tf`

```hcl
# modules/libvirt-network/outputs.tf
output "network_id" {
  description = "ID (UUID) of the created network"
  value       = libvirt_network.this.id
}

output "network_name" {
  description = "Name of the created network. VM interfaces reference networks by name."
  value       = libvirt_network.this.name
}

output "cidr" {
  description = "IP range of the network"
  value       = var.cidr
}
```

#### 5. Create `versions.tf`

```hcl
# modules/libvirt-network/versions.tf
terraform {
  required_version = ">= 1.14"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
  }
}
```

#### 6. Create `README.md`

```markdown
# Libvirt Network Module

Creates a libvirt network with configurable options.

## Usage

```hcl
module "network" {
  source = "./modules/libvirt-network"
  
  network_name = "my-network"
  network_mode = "nat"
  cidr         = "10.17.3.0/24"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| network_name | Name of the network | string | - | yes |
| network_mode | nat, route or isolated | string | "nat" | no |
| cidr | IP range of the network | string | "10.17.3.0/24" | no |
| domain | DNS domain | string | "local" | no |
| enable_dns | Enable DNS | bool | true | no |
| enable_dhcp | Enable DHCP (.100-.200) | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| network_id | ID of the created network |
| network_name | Name of the network (VMs reference networks by name) |
| cidr | IP range of the network |
```

#### 7. Use the Module

Create `main.tf` in your root directory:

```hcl
# Root main.tf
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

module "app_network" {
  source = "./modules/libvirt-network"

  network_name = "app-network"
  network_mode = "nat"
  cidr         = "10.20.0.0/24"
}

module "db_network" {
  source = "./modules/libvirt-network"

  network_name = "db-network"
  network_mode = "isolated"
  cidr         = "10.30.0.0/24"
  enable_dhcp  = false
}

output "app_network_id" {
  value = module.app_network.network_id
}

output "db_network_id" {
  value = module.db_network.network_id
}
```

#### 8. Test the Module

```bash
terraform init
terraform plan
terraform apply
```

### Key Takeaways

- ✅ Modules encapsulate resources
- ✅ Variables make modules flexible
- ✅ Outputs enable composition
- ✅ Validation ensures correct inputs
- ✅ Documentation is essential

---

## 💻 Hands-On Lab 2: Complex Module

### Objective
Create a complex multi-resource module for complete VM infrastructure.

### Duration
30 minutes

### Module: Complete VM with Network

This module creates:
- Network
- Storage pool
- Storage volume
- Cloud-init disk
- Virtual machine

#### 1. Create Module Structure

```bash
mkdir -p modules/libvirt-vm-complete
cd modules/libvirt-vm-complete
```

#### 2. Create `main.tf`

```hcl
# modules/libvirt-vm-complete/main.tf
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
  }
}

# Network: only created when no existing network_name is passed in
resource "libvirt_network" "vm_network" {
  count = var.network_name == null ? 1 : 0

  name      = "${var.vm_name}-network"
  autostart = true

  forward = { mode = "nat" }
  dns     = { enable = "yes" }

  ips = [
    {
      address = cidrhost(var.network_cidr, 1)
      prefix  = tonumber(split("/", var.network_cidr)[1])
      dhcp = {
        ranges = [
          {
            start = cidrhost(var.network_cidr, 100)
            end   = cidrhost(var.network_cidr, 200)
          }
        ]
      }
    }
  ]
}

locals {
  network_name = var.network_name != null ? var.network_name : libvirt_network.vm_network[0].name
}

# Storage Pool
resource "libvirt_pool" "vm_pool" {
  name   = "${var.vm_name}-pool"
  type   = "dir"
  target = { path = "/var/lib/libvirt/images/${var.vm_name}" }
}

# Base Volume (downloaded or copied from base_image_url)
resource "libvirt_volume" "base" {
  name = "${var.vm_name}-base.qcow2"
  pool = libvirt_pool.vm_pool.name
  create = {
    content = { url = var.base_image_url }
  }
  target = { format = { type = "qcow2" } }
}

# VM Volume (copy-on-write clone of the base)
resource "libvirt_volume" "vm" {
  name     = "${var.vm_name}.qcow2"
  pool     = libvirt_pool.vm_pool.name
  capacity = var.disk_size_bytes
  backing_store = {
    path   = libvirt_volume.base.path
    format = { type = "qcow2" }
  }
  target = { format = { type = "qcow2" } }
}

# Cloud-init disk (built locally) ...
resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "${var.vm_name}-cloudinit.iso"
  user_data = var.cloud_init_user_data
  meta_data = yamlencode({
    instance-id    = var.vm_name
    local-hostname = var.vm_name
  })
}

# ... and uploaded to the pool so the VM can mount it
resource "libvirt_volume" "cloudinit" {
  name = "${var.vm_name}-cloudinit.iso"
  pool = libvirt_pool.vm_pool.name
  create = {
    content = { url = libvirt_cloudinit_disk.commoninit.path }
  }
}

# Virtual Machine
resource "libvirt_domain" "vm" {
  name        = var.vm_name
  memory      = var.memory_mb
  memory_unit = "MiB"
  vcpu        = var.vcpu_count
  type        = "kvm"
  running     = true
  autostart   = var.autostart

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_volume.vm.pool
            volume = libvirt_volume.vm.name
          }
        }
        target = { dev = "vda", bus = "virtio" }
        driver = { type = "qcow2" }
      },
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.cloudinit.pool
            volume = libvirt_volume.cloudinit.name
          }
        }
        target = { dev = "sda", bus = "sata" }
      }
    ]

    interfaces = [
      {
        model       = { type = "virtio" }
        source      = { network = { network = local.network_name } }
        wait_for_ip = { source = "lease" }
      }
    ]

    consoles = [
      {
        target = { type = "serial", port = 0 }
      }
    ]

    graphics = [
      {
        spice = { auto_port = true, listen = "127.0.0.1" }
      }
    ]
  }
}

data "libvirt_domain_interface_addresses" "vm" {
  domain = libvirt_domain.vm.name
  source = "lease"
}
```

#### 3. Create `variables.tf`

```hcl
# modules/libvirt-vm-complete/variables.tf
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.vm_name))
    error_message = "VM name must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "memory_mb" {
  description = "Memory in MiB"
  type        = number
  default     = 512

  validation {
    condition     = var.memory_mb >= 256 && var.memory_mb <= 16384
    error_message = "Memory must be between 256 MiB and 16 GiB"
  }
}

variable "vcpu_count" {
  description = "Number of virtual CPUs"
  type        = number
  default     = 1

  validation {
    condition     = var.vcpu_count >= 1 && var.vcpu_count <= 8
    error_message = "vCPU count must be between 1 and 8"
  }
}

variable "disk_size_bytes" {
  description = "Disk size in bytes"
  type        = number
  default     = 10737418240 # 10 GB
}

variable "network_name" {
  description = "Existing network to attach the VM to. Leave null to create a network from network_cidr."
  type        = string
  default     = null
}

variable "network_cidr" {
  description = "CIDR block for the network the module creates (ignored when network_name is set)"
  type        = string
  default     = "10.17.3.0/24"

  validation {
    condition     = can(cidrhost(var.network_cidr, 0))
    error_message = "Must be a valid CIDR block"
  }
}

variable "base_image_url" {
  description = "URL or local path of the base cloud image (qcow2)"
  type        = string
}

variable "cloud_init_user_data" {
  description = "Cloud-init user data"
  type        = string
  default     = <<-EOF
    #cloud-config
    users:
      - name: ubuntu
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
    EOF
}

variable "autostart" {
  description = "Start the VM when the host boots"
  type        = bool
  default     = true
}
```

#### 4. Create `outputs.tf`

```hcl
# modules/libvirt-vm-complete/outputs.tf
output "vm_id" {
  description = "UUID of the virtual machine (libvirt_domain.id is libvirt's runtime number)"
  value       = libvirt_domain.vm.uuid
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = libvirt_domain.vm.name
}

output "network_name" {
  description = "Name of the network (VM interfaces reference networks by name)"
  value       = local.network_name
}

output "ip_address" {
  description = "IP address of the VM, read from the DHCP leases"
  value       = try(data.libvirt_domain_interface_addresses.vm.interfaces[0].addrs[0].addr, null)
}

output "pool_name" {
  description = "Name of the storage pool"
  value       = libvirt_pool.vm_pool.name
}
```

#### 5. Use the Module

```hcl
# Root main.tf
module "web_server" {
  source = "./modules/libvirt-vm-complete"

  vm_name         = "web-server"
  memory_mb       = 1024
  vcpu_count      = 2
  disk_size_bytes = 21474836480 # 20 GB
  network_cidr    = "10.20.0.0/24"
  base_image_url  = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"

  cloud_init_user_data = <<-EOF
    #cloud-config
    users:
      - name: ubuntu
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
    packages:
      - nginx
    runcmd:
      - systemctl enable nginx
      - systemctl start nginx
  EOF
}

output "web_server_ip" {
  value = module.web_server.ip_address
}
```

### Key Takeaways

- ✅ Complex modules manage multiple related resources
- ✅ Resource dependencies are handled automatically
- ✅ Modules can create complete infrastructure stacks
- ✅ Cloud-init enables VM customization
- ✅ Outputs expose important information

---

## 💻 Hands-On Lab 3: Module Composition

### Objective
Compose multiple modules together to build a complete application infrastructure.

### Duration
30 minutes

### Scenario
Build a 3-tier application:
- Web tier (2 VMs)
- App tier (2 VMs)
- Database tier (1 VM)

Each tier has its own network.

#### Solution

One design question first: `libvirt-vm-complete` from Lab 2 creates its own network for every VM. Two web VMs would then create two networks with the same CIDR, which libvirt refuses to run side by side. The module therefore has an optional `network_name` input: pass an existing network and the module skips creating one (`count = var.network_name == null ? 1 : 0`). This "bring your own, or I'll make one" pattern is common in reusable modules.

```hcl
# Root main.tf
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

locals {
  base_image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

# Networks for each tier
module "web_network" {
  source = "./modules/libvirt-network"

  network_name = "web-tier"
  cidr         = "10.10.0.0/24"
}

module "app_network" {
  source = "./modules/libvirt-network"

  network_name = "app-tier"
  cidr         = "10.40.0.0/24"
}

module "db_network" {
  source = "./modules/libvirt-network"

  network_name = "db-tier"
  cidr         = "10.50.0.0/24"
}

# Web tier VMs: attach to the shared tier network instead of creating one each
module "web_vm_1" {
  source = "./modules/libvirt-vm-complete"

  vm_name        = "web-01"
  memory_mb      = 1024
  vcpu_count     = 2
  network_name   = module.web_network.network_name
  base_image_url = local.base_image_url
}

module "web_vm_2" {
  source = "./modules/libvirt-vm-complete"

  vm_name        = "web-02"
  memory_mb      = 1024
  vcpu_count     = 2
  network_name   = module.web_network.network_name
  base_image_url = local.base_image_url
}

# App tier VMs
module "app_vm_1" {
  source = "./modules/libvirt-vm-complete"

  vm_name        = "app-01"
  memory_mb      = 2048
  vcpu_count     = 2
  network_name   = module.app_network.network_name
  base_image_url = local.base_image_url
}

module "app_vm_2" {
  source = "./modules/libvirt-vm-complete"

  vm_name        = "app-02"
  memory_mb      = 2048
  vcpu_count     = 2
  network_name   = module.app_network.network_name
  base_image_url = local.base_image_url
}

# Database tier VM
module "db_vm" {
  source = "./modules/libvirt-vm-complete"

  vm_name         = "db-01"
  memory_mb       = 4096
  vcpu_count      = 4
  disk_size_bytes = 53687091200 # 50 GB
  network_name    = module.db_network.network_name
  base_image_url  = local.base_image_url
}

# Outputs
output "web_tier_ips" {
  value = {
    web-01 = module.web_vm_1.ip_address
    web-02 = module.web_vm_2.ip_address
  }
}

output "app_tier_ips" {
  value = {
    app-01 = module.app_vm_1.ip_address
    app-02 = module.app_vm_2.ip_address
  }
}

output "db_tier_ip" {
  value = module.db_vm.ip_address
}
```

### Key Takeaways

- ✅ Modules enable infrastructure composition
- ✅ Reuse modules multiple times with different inputs
- ✅ Build complex architectures from simple modules
- ✅ Outputs enable cross-module references
- ✅ Consistent patterns across tiers

---

## 📝 Checkpoint Quiz

### Question 1: Module Purpose
**What is the PRIMARY purpose of Terraform modules?**

A) To make Terraform run faster  
B) To enable code reusability and organization  
C) To reduce the size of state files  
D) To automatically fix syntax errors

<details>
<summary>Show Answer</summary>

**Answer: B** - To enable code reusability and organization

**Explanation**: Modules are containers for multiple resources that promote:
- Code reusability across projects
- Better organization of complex configurations
- Encapsulation of infrastructure patterns
- Easier maintenance and updates
- Team collaboration through shared components
</details>

---

### Question 2: Module Structure
**Which file is REQUIRED in every Terraform module?**

A) README.md  
B) outputs.tf  
C) At least one .tf file  
D) versions.tf

<details>
<summary>Show Answer</summary>

**Answer: C** - At least one .tf file

**Explanation**: A module must have at least one `.tf` file containing Terraform configuration. While `variables.tf`, `outputs.tf`, `versions.tf`, and `README.md` are best practices, only having Terraform configuration files is technically required.
</details>

---

### Question 3: Module Inputs
**How do you pass values into a module?**

A) Using environment variables  
B) Using input variables  
C) Using command-line flags  
D) Using data sources

<details>
<summary>Show Answer</summary>

**Answer: B** - Using input variables

**Explanation**: Modules receive inputs through variables defined in `variables.tf`. When calling a module, you pass values to these variables:

```hcl
module "example" {
  source = "./modules/example"
  
  # Passing values to module variables
  name   = "my-resource"
  count  = 3
}
```
</details>

---

### Question 4: Module Outputs
**Why are module outputs important?**

A) They make modules run faster  
B) They enable module composition and data sharing  
C) They are required for all modules  
D) They automatically create documentation

<details>
<summary>Show Answer</summary>

**Answer: B** - They enable module composition and data sharing

**Explanation**: Outputs allow:
- Parent modules to access child module data
- Module composition (one module using another's outputs)
- Exposing important information to users
- Creating dependencies between modules

Example:
```hcl
module "network" {
  source = "./modules/network"
}

module "vm" {
  source     = "./modules/vm"
  network_name = module.network.network_name  # Using output
}
```
</details>

---

### Question 5: Module Versioning
**What is the benefit of versioning modules?**

A) It makes modules load faster  
B) It ensures stability and controlled updates  
C) It's required by Terraform  
D) It automatically fixes bugs

<details>
<summary>Show Answer</summary>

**Answer: B** - It ensures stability and controlled updates

**Explanation**: Module versioning provides:
- Stability - pin to known working versions
- Controlled updates - test new versions before upgrading
- Rollback capability - revert to previous versions
- Team coordination - everyone uses same version

Example:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"  # Pin to specific version
}
```
</details>

---

### Question 6: Provider Configuration
**Should you include provider blocks in reusable modules?**

A) Yes, always  
B) No, never  
C) Only for complex modules  
D) Only for published modules

<details>
<summary>Show Answer</summary>

**Answer: B** - No, never

**Explanation**: Provider blocks should NOT be in reusable modules because:
- Prevents using meta-arguments (`count`, `for_each`, `depends_on`)
- Causes issues when reusing modules in different environments
- Makes modules less flexible
- Can cause provider configuration conflicts

Instead, define providers in the root module and modules inherit them.
</details>

---

## 📖 Module Best Practices

### 1. Keep Modules Focused

✅ **Good**: Single-purpose modules
```hcl
module "network"  # Creates networks only
module "vm"       # Creates VMs only
module "storage"  # Creates storage only
```

❌ **Bad**: Monolithic modules
```hcl
module "everything"  # Creates networks, VMs, storage, databases...
```

### 2. Use Consistent Naming

```hcl
# Module names
modules/
├── libvirt-network/
├── libvirt-vm/
└── libvirt-storage/

# Resource names within modules
resource "libvirt_network" "this" { }  # Use "this" for single resources
resource "libvirt_domain" "vm" { }     # Use descriptive names
```

### 3. Document Everything

```hcl
variable "vm_name" {
  description = "Name of the virtual machine (lowercase, alphanumeric, hyphens only)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.vm_name))
    error_message = "VM name must contain only lowercase letters, numbers, and hyphens"
  }
}
```

### 4. Validate Inputs

```hcl
variable "memory_mb" {
  description = "Memory in MB"
  type        = number
  
  validation {
    condition     = var.memory_mb >= 256 && var.memory_mb <= 16384
    error_message = "Memory must be between 256 MB and 16 GB"
  }
}
```

### 5. Use Semantic Versioning

For published modules:
- **Major** (1.0.0): Breaking changes
- **Minor** (1.1.0): New features, backward compatible
- **Patch** (1.1.1): Bug fixes

### 6. Provide Examples

```
modules/libvirt-vm/
├── main.tf
├── variables.tf
├── outputs.tf
├── README.md
└── examples/
    ├── basic/
    │   └── main.tf
    ├── advanced/
    │   └── main.tf
    └── multi-vm/
        └── main.tf
```

### 7. Test Your Modules

Use Terraform's test framework (TF-303):
```hcl
# tests/basic.tftest.hcl
run "create_network" {
  command = apply
  
  assert {
    condition     = libvirt_network.this.name == "test-network"
    error_message = "Network name mismatch"
  }
}
```

### 8. Use Data Sources

```hcl
# Look things up instead of hardcoding them
data "libvirt_node_info" "host" {}

locals {
  host_memory_mb = floor(data.libvirt_node_info.host.memory_total_kb / 1024)
  # Never give a single VM more than a quarter of the host's memory
  vm_memory_mb = min(var.memory_mb, floor(local.host_memory_mb / 4))
}
```

Which data sources exist depends entirely on the provider. The libvirt provider 0.9.x has only a handful (`libvirt_node_info`, `libvirt_node_devices`, `libvirt_node_device_info`, `libvirt_domain_interface_addresses`) and no network data source. That's less of a loss than it sounds: VM interfaces reference networks by name, so an existing network like `default` is just the string `"default"`.

### 9. Follow DRY Principle

Don't Repeat Yourself - if you're copying code, create a module:

❌ **Bad**: Repeated code
```hcl
# Repeated in multiple files
resource "libvirt_network" "web" { ... }
resource "libvirt_network" "app" { ... }
resource "libvirt_network" "db" { ... }
```

✅ **Good**: Module reuse
```hcl
module "web_network" { source = "./modules/network" }
module "app_network" { source = "./modules/network" }
module "db_network" { source = "./modules/network" }
```

### 10. Use Terraform Formatting

```bash
# Format all files
terraform fmt -recursive

# Check formatting
terraform fmt -check -recursive
```

---

## 🎓 Module Versioning

### Local Modules

```hcl
module "network" {
  source = "./modules/libvirt-network"  # Relative path
}

module "vm" {
  source = "../shared-modules/vm"  # Parent directory
}
```

### Git Modules

```hcl
module "network" {
  source = "git::https://github.com/org/terraform-modules.git//network?ref=v1.0.0"
}
```

### Registry Modules

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
}
```

### Version Constraints

```hcl
module "example" {
  source  = "registry.terraform.io/org/module/provider"
  version = "~> 1.0"  # >= 1.0, < 2.0
}
```

---

## 🔗 Module Composition Patterns

### Pattern 1: Layered Architecture

```hcl
# Layer 1: Foundation
module "networks" { }

# Layer 2: Compute (depends on Layer 1)
module "vms" {
  network_name = module.networks.network_name
}

# Layer 3: Applications (depends on Layer 2)
module "apps" {
  vm_ips = module.vms.ip_addresses
}
```

### Pattern 2: Environment Modules

```hcl
# modules/environment/main.tf
module "network" { source = "../network" }
module "vms" { source = "../vms" }
module "storage" { source = "../storage" }

# Root main.tf
module "dev" {
  source = "./modules/environment"
  env    = "dev"
}

module "prod" {
  source = "./modules/environment"
  env    = "prod"
}
```

### Pattern 3: Feature Modules

```hcl
module "monitoring" {
  source = "./modules/monitoring"
  vms    = module.vms.vm_ids
}

module "backup" {
  source  = "./modules/backup"
  volumes = module.storage.volume_ids
}
```

---

## 📚 Additional Resources

### Official Documentation
- [Terraform Modules](https://developer.hashicorp.com/terraform/language/modules)
- [Module Development](https://developer.hashicorp.com/terraform/language/modules/develop)
- [Standard Module Structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
- [Publishing Modules](https://developer.hashicorp.com/terraform/registry/modules/publish)

### Community Resources
- [Terraform Registry](https://registry.terraform.io/) - Public modules
- [Module Best Practices](https://www.terraform-best-practices.com/modules)
- [Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)

---

## 🆕 Dynamic Module Sources (Terraform 1.15+)

**New Feature**: Since Terraform 1.15, a module's `source` and `version` can use input variables declared with `const = true`, and locals built only from those and literals.

### Basic Example

```hcl
variable "network_module_version" {
  type    = string
  default = "v1"
  const   = true # usable during terraform init
}

module "network" {
  source = "./modules/network/${var.network_module_version}"
}
```

`terraform init` installs modules before any plan, so it has to know every `source` and `version` up front. That's what `const` promises: a value known from the start (default, `-var`, `TF_VAR_`, `.tfvars`) that doesn't depend on anything computed during plan. An ordinary variable in `source` fails with *Only literal values and const variables can be evaluated during init*.

### Things to Know

- `plan` and `apply` must use the same values as `init`, or Terraform stops with *Module source has changed*
- `version` only applies to registry modules
- `terraform test` uses the modules `init` installed: a run block that changes a `const` variable doesn't switch modules, and doesn't warn

### Hands-On Lab

- **Location**: [`dynamic-module-sources/`](dynamic-module-sources/README.md)
- **Scenario**: two versions of a network module, picked per environment (dev tries v2, prod stays on v1), and a registry module version from a `const` variable
- **Runs locally**: no provider or cloud account needed

## 📂 Supplemental Content

| Supplement | Topic | Directory |
|------------|-------|-----------|
| `moved` Blocks | Code-driven refactoring without destroy/recreate (Terraform 1.1+) | [`moved-blocks/`](./moved-blocks/) |

---

## 🎉 Congratulations!

You've completed TF-201: Module Design & Composition!

### What You've Learned

- ✅ Module fundamentals and structure
- ✅ Creating simple and complex modules
- ✅ Module inputs and outputs
- ✅ Module composition patterns
- ✅ Best practices and conventions
- ✅ Module versioning strategies
- ✅ `moved` blocks for safe refactoring (Terraform 1.1+)

### Next Steps

**Continue to TF-202**: Advanced Module Patterns
- Private module registries
- Canary deployments
- Module testing strategies
- Advanced composition patterns

---

**Ready to master advanced module patterns?** Continue to TF-202! 🚀
