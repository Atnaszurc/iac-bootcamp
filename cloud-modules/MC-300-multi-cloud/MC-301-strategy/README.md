# MC-301: Multi-Cloud Strategy & Design

**Course**: MC-300 Multi-Cloud Architecture  
**Module**: MC-301  
**Duration**: 1 hour  
**Prerequisites**: AWS-200 and/or AZ-200 (at least one cloud module)  
**Difficulty**: Advanced

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Why Multi-Cloud?](#why-multi-cloud)
4. [Multi-Cloud Patterns](#multi-cloud-patterns)
5. [Terraform Multi-Cloud Setup](#terraform-multi-cloud-setup)
6. [State Management Strategy](#state-management-strategy)
7. [Workspace Strategy](#workspace-strategy)
8. [Cost and Governance](#cost-and-governance)
9. [Best Practices](#best-practices)
10. [Hands-On Labs](#hands-on-labs)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course introduces multi-cloud architecture strategy and how to design Terraform configurations that span multiple cloud providers. You'll learn when and why to use multiple clouds, how to structure your Terraform code for multi-cloud deployments, and the trade-offs involved.

### What You'll Learn

By the end of this course, you'll be able to:
- Articulate the business and technical reasons for multi-cloud
- Design a multi-cloud Terraform project structure
- Configure multiple providers in a single Terraform workspace
- Manage state across cloud providers
- Apply governance and cost management strategies

### Course Structure

```
MC-301-strategy/
├── README.md                          # This file
└── example/
    ├── main.tf                        # Multi-provider configuration
    ├── providers.tf                   # Provider configurations
    ├── variables.tf                   # Input variables
    ├── outputs.tf                     # Output values
    └── versions.tf                    # Version constraints
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Evaluate Multi-Cloud Decisions**
   - Identify valid use cases for multi-cloud
   - Understand the complexity trade-offs
   - Choose the right pattern for your needs

2. **Design Multi-Cloud Architecture**
   - Structure Terraform for multiple providers
   - Plan state management strategy
   - Design for portability

3. **Configure Multiple Providers**
   - Use provider aliases
   - Configure credentials for each cloud
   - Manage provider versions

4. **Implement Governance**
   - Tag resources consistently across clouds
   - Implement cost allocation
   - Apply consistent security policies

---

## ☁️ Why Multi-Cloud?

### Valid Business Reasons

```
✅ Avoid vendor lock-in
✅ Best-of-breed services (e.g., AWS ML + Azure AD)
✅ Regulatory requirements (data residency)
✅ Mergers and acquisitions
✅ Disaster recovery across providers
✅ Geographic coverage (provider availability)
✅ Cost optimization (spot/preemptible instances)
```

### When NOT to Use Multi-Cloud

```
❌ Just to say you're "cloud-agnostic"
❌ When it adds complexity without benefit
❌ When team lacks expertise in both clouds
❌ For simple workloads that fit one cloud
❌ When cost of management exceeds savings
```

### Multi-Cloud vs Hybrid Cloud

| Aspect | Multi-Cloud | Hybrid Cloud |
|--------|-------------|--------------|
| Definition | Multiple public clouds | Public cloud + on-premises |
| Complexity | High | Medium |
| Use Case | Best-of-breed, redundancy | Data sovereignty, legacy |
| Terraform | Multiple cloud providers | Cloud + VMware/Libvirt |

---

## 🏗️ Multi-Cloud Patterns

### Pattern 1: Active-Active (Redundancy)

```
Users → Global Load Balancer
         ├── AWS Region (us-east-1)
         │   └── Application Stack
         └── Azure Region (West Europe)
             └── Application Stack (identical)
```

**Use Case**: Maximum availability, zero-downtime failover  
**Complexity**: Very High  
**Cost**: 2x infrastructure cost

### Pattern 2: Active-Passive (DR)

```
Users → Primary Cloud (AWS)
         └── Application Stack (active)
         
Standby → Secondary Cloud (Azure)
           └── Application Stack (warm standby)
```

**Use Case**: Disaster recovery, compliance  
**Complexity**: High  
**Cost**: 1.5x infrastructure cost

### Pattern 3: Workload Distribution

```
AWS:
├── Machine Learning (SageMaker)
├── Data Analytics (Redshift)
└── Lambda Functions

Azure:
├── Active Directory (Azure AD)
├── Office 365 Integration
└── Windows Workloads
```

**Use Case**: Best-of-breed services  
**Complexity**: Medium  
**Cost**: Optimized per workload

### Pattern 4: Cloud Bursting

```
On-Premises / Primary Cloud:
└── Baseline workload (always running)

Secondary Cloud:
└── Burst capacity (scale on demand)
```

**Use Case**: Variable workloads, cost optimization  
**Complexity**: Medium  
**Cost**: Pay only for burst

---

## 🔧 Terraform Multi-Cloud Setup

### Provider Configuration

```hcl
# providers.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}

# Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}
```

### Provider Aliases (Multiple Regions)

```hcl
# AWS - Primary region
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

# AWS - Secondary region
provider "aws" {
  alias  = "secondary"
  region = "eu-west-1"
}

# Azure - Primary region
provider "azurerm" {
  alias = "primary"
  features {}
  subscription_id = var.azure_subscription_id
}

# Use alias in resources
resource "aws_instance" "primary" {
  provider = aws.primary
  # ...
}

resource "aws_instance" "secondary" {
  provider = aws.secondary
  # ...
}
```

### Variables for Multi-Cloud

```hcl
# variables.tf

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "azure_region" {
  description = "Primary Azure region"
  type        = string
  default     = "West Europe"
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project_name" {
  description = "Project name (used across all clouds)"
  type        = string
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

### Deploying to Both Clouds

```hcl
# main.tf

# AWS resources
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = merge(local.common_tags, {
    Name  = "${var.project_name}-vpc"
    Cloud = "AWS"
  })
}

# Azure resources
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg"
  location = var.azure_region
  
  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}
```

---

## 🗂️ State Management Strategy

### Option 1: Single State File (Simple)

```hcl
# All resources in one state file
# ✅ Simple to manage
# ❌ Large blast radius
# ❌ Slow for large deployments

terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "multi-cloud/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### Option 2: Separate State per Cloud (Recommended)

```
terraform-state/
├── aws/
│   ├── networking/terraform.tfstate
│   ├── compute/terraform.tfstate
│   └── database/terraform.tfstate
└── azure/
    ├── networking/terraform.tfstate
    ├── compute/terraform.tfstate
    └── database/terraform.tfstate
```

```hcl
# AWS state in S3
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "aws/networking/terraform.tfstate"
    region = "us-east-1"
  }
}

# Azure state in Azure Storage
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatestorage"
    container_name       = "tfstate"
    key                  = "azure/networking/terraform.tfstate"
  }
}
```

### Option 3: Terraform Cloud (Enterprise)

```hcl
terraform {
  cloud {
    organization = "my-org"
    
    workspaces {
      tags = ["multi-cloud", "production"]
    }
  }
}
```

### Cross-Cloud State References

```hcl
# Reference AWS state from Azure configuration
data "terraform_remote_state" "aws_networking" {
  backend = "s3"
  
  config = {
    bucket = "my-terraform-state"
    key    = "aws/networking/terraform.tfstate"
    region = "us-east-1"
  }
}

# Use AWS output in Azure resource
resource "azurerm_virtual_network_gateway_connection" "vpn" {
  # Connect to AWS VPN endpoint from state
  peer_virtual_network_gateway_id = data.terraform_remote_state.aws_networking.outputs.vpn_gateway_id
}
```

---

## 🔀 Workspace Strategy

### Environment-Based Workspaces

```bash
# Create workspaces for each environment
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch workspace
terraform workspace select prod
```

```hcl
# Use workspace in configuration
locals {
  env_config = {
    dev = {
      aws_instance_type  = "t3.micro"
      azure_vm_size      = "Standard_B1s"
      replicas           = 1
    }
    staging = {
      aws_instance_type  = "t3.small"
      azure_vm_size      = "Standard_B2s"
      replicas           = 2
    }
    prod = {
      aws_instance_type  = "t3.medium"
      azure_vm_size      = "Standard_D2s_v3"
      replicas           = 3
    }
  }
  
  config = local.env_config[terraform.workspace]
}
```

---

## 💰 Cost and Governance

### Consistent Tagging Strategy

```hcl
# Enforce consistent tags across all clouds
locals {
  required_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.team_name
    CostCenter  = var.cost_center
    ManagedBy   = "Terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}

# AWS resource
resource "aws_instance" "web" {
  tags = merge(local.required_tags, {
    Name  = "${var.project_name}-web"
    Cloud = "AWS"
  })
}

# Azure resource
resource "azurerm_linux_virtual_machine" "web" {
  tags = merge(local.required_tags, {
    Cloud = "Azure"
  })
}
```

### Cost Allocation

```hcl
# Use consistent cost center tags
variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  
  validation {
    condition     = can(regex("^CC-[0-9]{4}$", var.cost_center))
    error_message = "Cost center must be in format CC-XXXX."
  }
}
```

---

## ✅ Best Practices

### 1. Abstract Cloud-Specific Details

```hcl
# ✅ Use variables to abstract cloud differences
variable "cloud_provider" {
  description = "Primary cloud provider"
  type        = string
  
  validation {
    condition     = contains(["aws", "azure"], var.cloud_provider)
    error_message = "Must be 'aws' or 'azure'."
  }
}
```

### 2. Consistent Naming Conventions

```hcl
# Use the same naming pattern across clouds
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# AWS
resource "aws_vpc" "main" {
  tags = { Name = "${local.name_prefix}-vpc" }
}

# Azure
resource "azurerm_virtual_network" "main" {
  name = "${local.name_prefix}-vnet"
}
```

### 3. Document Cloud-Specific Decisions

```hcl
# Comment why a specific cloud is used for each workload
# AWS: Used for ML workloads (SageMaker)
resource "aws_sagemaker_domain" "ml" { ... }

# Azure: Used for AD integration (Azure AD)
resource "azurerm_active_directory_domain_service" "main" { ... }
```

### 4. Test Each Cloud Independently

```
# Test AWS configuration
cd aws/
terraform init
terraform plan

# Test Azure configuration
cd azure/
terraform init
terraform plan
```

---

## 🔬 Hands-On Labs

### Lab 1: Multi-Provider Configuration (15 minutes)

**Objective**: Configure Terraform to use both AWS and Azure providers.

**Tasks**:
1. Create `providers.tf` with both AWS and AzureRM providers
2. Configure credentials for both providers
3. Run `terraform init` to download both providers
4. Create one resource in each cloud (e.g., S3 bucket + Azure Storage Account)
5. Run `terraform plan` and review the multi-cloud plan
6. Apply and verify resources in both clouds

**Expected Output**:
- Both providers initialized
- Resources created in AWS and Azure
- Single `terraform apply` manages both clouds

---

### Lab 2: Cross-Cloud State References (15 minutes)

**Objective**: Reference outputs from one cloud's state in another cloud's configuration.

**Tasks**:
1. Create AWS networking configuration with remote state
2. Output VPC CIDR and VPN gateway details
3. Create Azure configuration that reads AWS state
4. Use AWS outputs to configure Azure VNet peering
5. Verify cross-cloud state reference works

**Expected Output**:
- AWS state stored in S3
- Azure configuration reads AWS state
- Cross-cloud data flow working

---

### Lab 3: Consistent Tagging (10 minutes)

**Objective**: Implement consistent tagging across AWS and Azure.

**Tasks**:
1. Define `required_tags` local with common fields
2. Apply tags to AWS resources
3. Apply same tags to Azure resources
4. Add cloud-specific tag (`Cloud = "AWS"` / `Cloud = "Azure"`)
5. Verify tags in both cloud consoles

**Expected Output**:
- Consistent tags on all resources
- Cloud-specific tags added
- Cost center properly allocated

---

## 📝 Checkpoint Quiz

### Question 1: Multi-Cloud Motivation
**Which is the BEST reason to adopt a multi-cloud strategy?**

A) To appear more technically sophisticated  
B) To use best-of-breed services from different providers  
C) Because it's always cheaper  
D) To avoid learning one cloud deeply

<details>
<summary>Click to reveal answer</summary>

**Answer: B) To use best-of-breed services from different providers**

The strongest justification for multi-cloud is leveraging specific strengths of each provider (e.g., AWS for ML, Azure for AD integration). Complexity should be justified by clear business value.
</details>

---

### Question 2: Provider Aliases
**When would you use provider aliases in Terraform?**

A) When using multiple versions of the same provider  
B) When deploying to multiple regions or accounts with the same provider  
C) When switching between dev and prod  
D) When using Terraform Cloud

<details>
<summary>Click to reveal answer</summary>

**Answer: B) When deploying to multiple regions or accounts with the same provider**

Provider aliases allow you to configure the same provider multiple times with different settings (region, account, subscription). Resources then reference the specific alias they should use.
</details>

---

### Question 3: State Strategy
**What is the recommended state management approach for multi-cloud?**

A) Single state file for all clouds  
B) Separate state files per cloud/component  
C) No remote state needed  
D) One state file per resource

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Separate state files per cloud/component**

Separate state files reduce blast radius, improve performance, and allow independent management of each cloud's resources. Cross-cloud references use `terraform_remote_state` data sources.
</details>

---

### Question 4: Active-Active vs Active-Passive
**What is the main trade-off of Active-Active multi-cloud vs Active-Passive?**

A) Active-Active is cheaper but less available  
B) Active-Active provides higher availability but at roughly 2x cost  
C) Active-Passive is more complex to implement  
D) There is no meaningful difference

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Active-Active provides higher availability but at roughly 2x cost**

Active-Active runs full infrastructure in both clouds simultaneously, providing zero-downtime failover but doubling infrastructure costs. Active-Passive keeps a warm standby, reducing cost but with some failover time.
</details>

---

### Question 5: Tagging Strategy
**Why is consistent tagging critical in multi-cloud environments?**

A) Required by cloud providers  
B) Enables cost allocation, governance, and resource tracking across clouds  
C) Improves performance  
D) Required for Terraform to work

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Enables cost allocation, governance, and resource tracking across clouds**

Consistent tags across clouds allow finance teams to allocate costs by project/team, security teams to audit resources, and operations teams to identify and manage resources regardless of which cloud they're in.
</details>

---

### Question 6: Complexity Trade-off
**When should you NOT use multi-cloud?**

A) When you have more than 100 resources  
B) When the added complexity doesn't provide clear business value  
C) When using Terraform  
D) When your team is large

<details>
<summary>Click to reveal answer</summary>

**Answer: B) When the added complexity doesn't provide clear business value**

Multi-cloud significantly increases operational complexity (multiple skill sets, tools, billing, security models). It should only be adopted when the business benefits clearly outweigh this complexity cost.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [Terraform Multiple Providers](https://developer.hashicorp.com/terraform/language/providers/configuration)
- [Provider Aliases](https://developer.hashicorp.com/terraform/language/providers/configuration#alias-multiple-provider-configurations)
- [Remote State](https://developer.hashicorp.com/terraform/language/state/remote-state-data)

### Next Steps
- **Next Course**: [MC-302: Provider Abstraction Patterns](../MC-302-abstraction/README.md)
- **Module Overview**: [MC-300: Multi-Cloud Architecture](../README.md)

---

*Part of the [Hashi-Training](../../../README.md) curriculum - MC-300: Multi-Cloud Architecture*