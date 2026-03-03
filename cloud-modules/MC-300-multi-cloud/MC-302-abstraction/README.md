# MC-302: Provider Abstraction Patterns

**Course**: MC-300 Multi-Cloud Architecture  
**Module**: MC-302  
**Duration**: 1 hour  
**Prerequisites**: MC-301 (Multi-Cloud Strategy)  
**Difficulty**: Advanced

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Abstraction Concepts](#abstraction-concepts)
4. [Cloud-Agnostic Modules](#cloud-agnostic-modules)
5. [Interface Pattern](#interface-pattern)
6. [Factory Pattern](#factory-pattern)
7. [Conditional Provider Selection](#conditional-provider-selection)
8. [Data Normalization](#data-normalization)
9. [Best Practices](#best-practices)
10. [Hands-On Labs](#hands-on-labs)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course teaches you how to write Terraform code that abstracts cloud provider differences, enabling you to deploy the same logical infrastructure to multiple clouds with minimal code duplication. You'll learn design patterns that make your infrastructure code portable and maintainable.

### What You'll Learn

By the end of this course, you'll be able to:
- Design cloud-agnostic Terraform modules
- Implement the interface pattern for multi-cloud
- Use the factory pattern to select providers dynamically
- Normalize outputs across cloud providers
- Build reusable abstraction layers

### Course Structure

```
MC-302-abstraction/
├── README.md                          # This file
└── example/
    ├── main.tf                        # Consumer of abstraction modules
    ├── modules/
    │   ├── cloud-vm/                  # Cloud-agnostic VM module
    │   │   ├── main.tf
    │   │   ├── aws.tf
    │   │   ├── azure.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   └── cloud-network/             # Cloud-agnostic network module
    │       ├── main.tf
    │       ├── aws.tf
    │       ├── azure.tf
    │       ├── variables.tf
    │       └── outputs.tf
    ├── variables.tf
    └── versions.tf
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Design Abstraction Layers**
   - Identify what to abstract vs what to keep cloud-specific
   - Design consistent interfaces for cloud resources
   - Balance abstraction with flexibility

2. **Implement Cloud-Agnostic Modules**
   - Create modules that work across providers
   - Use conditional logic for provider selection
   - Normalize resource outputs

3. **Apply Design Patterns**
   - Interface pattern for consistent APIs
   - Factory pattern for provider selection
   - Adapter pattern for output normalization

4. **Manage Complexity**
   - Know when abstraction helps vs hurts
   - Document abstraction decisions
   - Test across multiple providers

---

## 🧩 Abstraction Concepts

### What to Abstract

```
✅ Good candidates for abstraction:
- Virtual machines (EC2 vs Azure VM)
- Virtual networks (VPC vs VNet)
- Object storage (S3 vs Blob Storage)
- Load balancers (ALB vs Azure LB)
- DNS records (Route53 vs Azure DNS)

❌ Poor candidates for abstraction:
- Cloud-specific managed services (SageMaker, Azure ML)
- Provider-specific security models (IAM vs RBAC)
- Cloud-native features (Lambda vs Azure Functions)
- Pricing models and reserved instances
```

### Abstraction Trade-offs

| Benefit | Cost |
|---------|------|
| Portability | Reduced cloud-native features |
| Consistency | Increased complexity |
| Reusability | Lowest common denominator |
| Vendor flexibility | More code to maintain |

### The Abstraction Spectrum

```
Low Abstraction                          High Abstraction
     │                                         │
     ▼                                         ▼
Cloud-specific          Thin wrapper      Cloud-agnostic
  resources          (same interface)       modules
  
aws_instance          cloud_vm module      compute module
azurerm_linux_vm      (AWS or Azure)       (any cloud)
```

---

## 📦 Cloud-Agnostic Modules

### Cloud-Agnostic VM Module

```hcl
# modules/cloud-vm/variables.tf

variable "cloud" {
  description = "Cloud provider to use"
  type        = string
  
  validation {
    condition     = contains(["aws", "azure"], var.cloud)
    error_message = "Cloud must be 'aws' or 'azure'."
  }
}

variable "name" {
  description = "VM name"
  type        = string
}

variable "size" {
  description = "VM size class (small, medium, large)"
  type        = string
  default     = "small"
  
  validation {
    condition     = contains(["small", "medium", "large"], var.size)
    error_message = "Size must be 'small', 'medium', or 'large'."
  }
}

variable "subnet_id" {
  description = "Subnet ID (cloud-specific format)"
  type        = string
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

# Size mapping per cloud
locals {
  size_map = {
    aws = {
      small  = "t3.micro"
      medium = "t3.small"
      large  = "t3.medium"
    }
    azure = {
      small  = "Standard_B1s"
      medium = "Standard_B2s"
      large  = "Standard_D2s_v3"
    }
  }
  
  instance_type = local.size_map[var.cloud][var.size]
}
```

```hcl
# modules/cloud-vm/aws.tf

resource "aws_instance" "this" {
  count = var.cloud == "aws" ? 1 : 0
  
  ami           = data.aws_ami.ubuntu[0].id
  instance_type = local.instance_type
  subnet_id     = var.subnet_id
  
  key_name = aws_key_pair.this[0].key_name
  
  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_key_pair" "this" {
  count = var.cloud == "aws" ? 1 : 0
  
  key_name   = "${var.name}-key"
  public_key = var.public_key
}

data "aws_ami" "ubuntu" {
  count = var.cloud == "aws" ? 1 : 0
  
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

```hcl
# modules/cloud-vm/azure.tf

resource "azurerm_network_interface" "this" {
  count = var.cloud == "azure" ? 1 : 0
  
  name                = "${var.name}-nic"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
  
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "this" {
  count = var.cloud == "azure" ? 1 : 0
  
  name                = var.name
  resource_group_name = var.azure_resource_group
  location            = var.azure_location
  size                = local.instance_type
  admin_username      = "azureuser"
  
  network_interface_ids = [azurerm_network_interface.this[0].id]
  
  admin_ssh_key {
    username   = "azureuser"
    public_key = var.public_key
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
  
  tags = var.tags
}
```

```hcl
# modules/cloud-vm/outputs.tf

output "id" {
  description = "VM ID (cloud-specific format)"
  value = var.cloud == "aws" ? (
    length(aws_instance.this) > 0 ? aws_instance.this[0].id : null
  ) : (
    length(azurerm_linux_virtual_machine.this) > 0 ? azurerm_linux_virtual_machine.this[0].id : null
  )
}

output "private_ip" {
  description = "Private IP address"
  value = var.cloud == "aws" ? (
    length(aws_instance.this) > 0 ? aws_instance.this[0].private_ip : null
  ) : (
    length(azurerm_network_interface.this) > 0 ? azurerm_network_interface.this[0].private_ip_address : null
  )
}

output "cloud" {
  description = "Cloud provider this VM was deployed to"
  value       = var.cloud
}
```

---

## 🔌 Interface Pattern

### Consistent Module Interface

The interface pattern defines a standard set of inputs and outputs that all cloud implementations must satisfy:

```hcl
# Standard interface for any "compute" module

# INPUTS (same for all clouds):
# - name: string
# - size: "small" | "medium" | "large"
# - network_id: string
# - public_key: string
# - tags: map(string)

# OUTPUTS (same for all clouds):
# - id: string
# - private_ip: string
# - public_ip: string (nullable)
# - cloud: string
```

### Using the Interface

```hcl
# main.tf - Consumer doesn't care which cloud

module "web_server" {
  source = "./modules/cloud-vm"
  
  cloud      = var.target_cloud  # "aws" or "azure"
  name       = "${var.project_name}-web"
  size       = "small"
  subnet_id  = local.subnet_id   # Resolved per cloud
  public_key = file("~/.ssh/id_rsa.pub")
  tags       = local.common_tags
}

# Same output regardless of cloud
output "web_server_ip" {
  value = module.web_server.private_ip
}
```

---

## 🏭 Factory Pattern

### Dynamic Provider Selection

```hcl
# variables.tf
variable "target_cloud" {
  description = "Target cloud for deployment"
  type        = string
  default     = "aws"
  
  validation {
    condition     = contains(["aws", "azure"], var.target_cloud)
    error_message = "Target cloud must be 'aws' or 'azure'."
  }
}

# locals.tf - Factory logic
locals {
  # Select subnet based on cloud
  subnet_id = var.target_cloud == "aws" ? (
    aws_subnet.web.id
  ) : (
    azurerm_subnet.web.id
  )
  
  # Select security group / NSG based on cloud
  security_group_id = var.target_cloud == "aws" ? (
    aws_security_group.web.id
  ) : (
    azurerm_network_security_group.web.id
  )
}
```

### Multi-Cloud Deployment with Factory

```hcl
# Deploy to both clouds simultaneously
module "aws_web" {
  source = "./modules/cloud-vm"
  
  cloud      = "aws"
  name       = "${var.project_name}-aws-web"
  size       = "small"
  subnet_id  = aws_subnet.web.id
  public_key = file("~/.ssh/id_rsa.pub")
  tags       = local.common_tags
}

module "azure_web" {
  source = "./modules/cloud-vm"
  
  cloud                = "azure"
  name                 = "${var.project_name}-azure-web"
  size                 = "small"
  subnet_id            = azurerm_subnet.web.id
  azure_location       = var.azure_region
  azure_resource_group = azurerm_resource_group.main.name
  public_key           = file("~/.ssh/id_rsa.pub")
  tags                 = local.common_tags
}

# Normalized outputs from both
output "all_web_servers" {
  value = {
    aws   = module.aws_web.private_ip
    azure = module.azure_web.private_ip
  }
}
```

---

## 📊 Data Normalization

### Normalizing Storage Outputs

```hcl
# modules/cloud-storage/outputs.tf

output "endpoint" {
  description = "Storage endpoint URL (normalized)"
  value = var.cloud == "aws" ? (
    "https://${aws_s3_bucket.this[0].bucket}.s3.amazonaws.com"
  ) : (
    azurerm_storage_account.this[0].primary_blob_endpoint
  )
}

output "bucket_name" {
  description = "Storage bucket/container name"
  value = var.cloud == "aws" ? (
    aws_s3_bucket.this[0].id
  ) : (
    azurerm_storage_container.this[0].name
  )
}
```

### Normalizing Network Outputs

```hcl
# modules/cloud-network/outputs.tf

output "network_id" {
  description = "Network ID (VPC ID or VNet ID)"
  value = var.cloud == "aws" ? (
    aws_vpc.this[0].id
  ) : (
    azurerm_virtual_network.this[0].id
  )
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value = var.cloud == "aws" ? (
    [for s in aws_subnet.this : s.id]
  ) : (
    [for s in azurerm_subnet.this : s.id]
  )
}

output "cidr_block" {
  description = "Network CIDR block"
  value = var.cloud == "aws" ? (
    aws_vpc.this[0].cidr_block
  ) : (
    azurerm_virtual_network.this[0].address_space[0]
  )
}
```

---

## ✅ Best Practices

### 1. Keep Abstractions Thin

```hcl
# ✅ Thin abstraction - exposes cloud-specific options
variable "extra_aws_config" {
  description = "Additional AWS-specific configuration"
  type        = any
  default     = {}
}

# ❌ Over-abstraction - hides important options
# Don't try to abstract everything into generic parameters
```

### 2. Document What's Abstracted

```hcl
# modules/cloud-vm/README.md
# This module abstracts:
# - VM instance type (mapped from small/medium/large)
# - OS image selection (always Ubuntu 22.04 LTS)
# - SSH key management
#
# This module does NOT abstract:
# - Cloud-specific networking (subnet_id is cloud-specific)
# - IAM/RBAC (handled separately)
# - Storage (use cloud-storage module)
```

### 3. Test Each Cloud Path

```hcl
# tests/cloud_vm_test.tftest.hcl

run "aws_vm_creation" {
  variables {
    cloud = "aws"
    name  = "test-vm"
    size  = "small"
  }
  
  assert {
    condition     = output.cloud == "aws"
    error_message = "Expected AWS cloud"
  }
}

run "azure_vm_creation" {
  variables {
    cloud = "azure"
    name  = "test-vm"
    size  = "small"
  }
  
  assert {
    condition     = output.cloud == "azure"
    error_message = "Expected Azure cloud"
  }
}
```

### 4. Version Your Abstraction Modules

```hcl
module "web_vm" {
  source  = "git::https://github.com/myorg/tf-modules.git//cloud-vm?ref=v2.0.0"
  
  cloud = "aws"
  # ...
}
```

---

## 🔬 Hands-On Labs

### Lab 1: Cloud-Agnostic VM Module (20 minutes)

**Objective**: Create a module that deploys a VM to either AWS or Azure.

**Tasks**:
1. Create `modules/cloud-vm/` directory structure
2. Define consistent variable interface
3. Implement AWS resource block (conditional)
4. Implement Azure resource block (conditional)
5. Create normalized outputs
6. Test with `cloud = "aws"` and `cloud = "azure"`

**Expected Output**:
- Module deploys to AWS when `cloud = "aws"`
- Module deploys to Azure when `cloud = "azure"`
- Same outputs regardless of cloud

---

### Lab 2: Size Abstraction (15 minutes)

**Objective**: Abstract VM sizes to t-shirt sizes (small/medium/large).

**Tasks**:
1. Create size mapping locals for AWS and Azure
2. Map "small" → t3.micro (AWS) / Standard_B1s (Azure)
3. Map "medium" → t3.small (AWS) / Standard_B2s (Azure)
4. Map "large" → t3.medium (AWS) / Standard_D2s_v3 (Azure)
5. Use size variable in VM resources
6. Verify correct instance type is selected

**Expected Output**:
- `size = "small"` creates t3.micro on AWS
- `size = "small"` creates Standard_B1s on Azure
- Size mapping is centralized and easy to update

---

### Lab 3: Normalized Outputs (15 minutes)

**Objective**: Create consistent outputs regardless of cloud provider.

**Tasks**:
1. Create outputs for: id, private_ip, public_ip, cloud
2. Use conditional expressions to select correct attribute
3. Test outputs with both AWS and Azure
4. Verify output names and types are identical

**Expected Output**:
- `output.id` works for both clouds
- `output.private_ip` works for both clouds
- Consumer code doesn't need cloud-specific logic

---

## 📝 Checkpoint Quiz

### Question 1: Abstraction Goal
**What is the primary goal of provider abstraction in Terraform?**

A) Reduce the number of resources  
B) Create a consistent interface that works across multiple cloud providers  
C) Improve Terraform performance  
D) Reduce cloud costs

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Create a consistent interface that works across multiple cloud providers**

Provider abstraction creates a consistent API (inputs/outputs) that hides cloud-specific implementation details, allowing consumers to deploy to different clouds without changing their code.
</details>

---

### Question 2: Count for Conditional Resources
**How do you conditionally create a resource for only one cloud provider?**

A) Use `if` statements  
B) Use `count = var.cloud == "aws" ? 1 : 0`  
C) Use separate modules for each cloud  
D) Use `enabled = false`

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Use `count = var.cloud == "aws" ? 1 : 0`**

Setting `count = 0` prevents resource creation. The ternary expression `var.cloud == "aws" ? 1 : 0` creates the resource only when the cloud variable matches.
</details>

---

### Question 3: Size Mapping
**Why use t-shirt sizes (small/medium/large) instead of cloud-specific instance types?**

A) Cloud providers require it  
B) It abstracts cloud-specific naming, making modules portable  
C) It's cheaper  
D) It improves performance

<details>
<summary>Click to reveal answer</summary>

**Answer: B) It abstracts cloud-specific naming, making modules portable**

T-shirt sizes provide a cloud-agnostic interface. The module internally maps "small" to the appropriate instance type for each cloud, so consumers don't need to know cloud-specific naming conventions.
</details>

---

### Question 4: Abstraction Limit
**Which type of service is a POOR candidate for cloud abstraction?**

A) Virtual machines  
B) Object storage  
C) Cloud-native managed services (SageMaker, Azure ML)  
D) Load balancers

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Cloud-native managed services (SageMaker, Azure ML)**

Cloud-native managed services have unique APIs, features, and pricing models that don't map well across providers. Abstracting them would result in a lowest-common-denominator interface that loses the value of the service.
</details>

---

### Question 5: Output Normalization
**What is the benefit of normalizing module outputs across cloud providers?**

A) Reduces the number of outputs  
B) Allows consumer code to work without cloud-specific logic  
C) Required by Terraform  
D) Improves state management

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Allows consumer code to work without cloud-specific logic**

When outputs have the same names and types regardless of cloud, the code that uses the module doesn't need conditional logic. This is the key benefit of the abstraction pattern.
</details>

---

### Question 6: Interface Pattern
**In the interface pattern, what must remain consistent across all cloud implementations?**

A) The internal resource names  
B) The input variable names, types, and output names/types  
C) The cloud provider version  
D) The number of resources created

<details>
<summary>Click to reveal answer</summary>

**Answer: B) The input variable names, types, and output names/types**

The interface (contract) consists of the module's inputs and outputs. As long as these remain consistent, the internal implementation can differ completely between clouds.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [Terraform Module Composition](https://developer.hashicorp.com/terraform/language/modules/develop/composition)
- [Conditional Expressions](https://developer.hashicorp.com/terraform/language/expressions/conditionals)
- [Count Meta-Argument](https://developer.hashicorp.com/terraform/language/meta-arguments/count)

### Next Steps
- **Next Course**: [MC-303: Cross-Cloud Networking](../MC-303-networking/README.md)
- **Previous Course**: [MC-301: Multi-Cloud Strategy](../MC-301-strategy/README.md)

---

*Part of the [Hashi-Training](../../../README.md) curriculum - MC-300: Multi-Cloud Architecture*