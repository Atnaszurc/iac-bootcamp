# TF-405: Terraform Stacks

**Course**: TF-400 HCP Terraform & Enterprise Features  
**Module**: TF-405  
**Duration**: 1 hour  
**Prerequisites**: TF-401 (HCP Terraform Fundamentals), TF-402 (Remote Runs & VCS Integration)  
**Difficulty**: Expert  
**Terraform Version**: 1.13+ (Stacks GA)  
**Requires**: HCP Terraform (not available in open-source Terraform)

---

## 📋 Table of Contents

1. [⚠️ HCP Terraform Required](#️-hcp-terraform-required)
2. [What Are Terraform Stacks?](#what-are-terraform-stacks)
3. [Stacks vs Workspaces vs Separate Configurations](#stacks-vs-workspaces-vs-separate-configurations)
4. [Core Concepts](#core-concepts)
5. [File Types](#file-types)
6. [Components](#components)
7. [Deployments](#deployments)
8. [The `terraform stacks` CLI](#the-terraform-stacks-cli)
9. [Hands-On Walkthrough](#hands-on-walkthrough)
10. [When to Use Stacks](#when-to-use-stacks)
11. [Limitations and Considerations](#limitations-and-considerations)
12. [🆕 New in Terraform 1.15: Stacks Improvements](#-new-in-terraform-115-stacks-improvements)
13. [Checkpoint Quiz](#checkpoint-quiz)
14. [Additional Resources](#additional-resources)

---

## ⚠️ HCP Terraform Required

> **This entire module requires HCP Terraform (app.terraform.io) and Terraform 1.13+.**
>
> Terraform Stacks **cannot be used** with:
> - Local backends (`terraform init` without a cloud block)
> - Open-source Terraform CLI alone
> - Terraform Enterprise (check your version — Stacks support varies)
>
> If you do not have an HCP Terraform account, you can still complete this module conceptually — all examples and exercises are designed to be readable and understandable without running them. Sign up for a free HCP Terraform account at [app.terraform.io](https://app.terraform.io).

---

## 🎯 What Are Terraform Stacks?

**Terraform Stacks** (introduced in Terraform 1.13) is a new orchestration layer that allows you to manage **multiple Terraform configurations as a single coordinated unit**.

Think of Stacks as a way to describe "I want this entire application deployed across these environments" — and have Terraform handle the coordination, ordering, and state management for all the pieces together.

### The Problem Stacks Solve

Without Stacks, deploying the same infrastructure to multiple environments (dev, staging, prod) requires:
- Multiple separate Terraform configurations (or workspaces)
- Manual coordination of apply order
- Separate state files with no built-in relationship
- Custom CI/CD pipelines to orchestrate the sequence

With Stacks:
- One Stack definition describes the entire deployment topology
- Deployments (like workspaces) represent each environment instance
- HCP Terraform orchestrates the apply order automatically
- All deployments share the same component definitions

---

## 🔄 Stacks vs Workspaces vs Separate Configurations

| Feature | Workspaces | Separate Configs | Stacks |
|---------|-----------|-----------------|--------|
| **Use case** | Same config, different state | Different configs | Multiple configs as a unit |
| **Coordination** | Manual | Manual | Automatic |
| **State** | One per workspace | One per config | One per component per deployment |
| **Environments** | Good fit | Complex | Excellent fit |
| **HCP required** | No | No | **Yes** |
| **Terraform version** | Any | Any | 1.13+ |
| **Complexity** | Low | Medium | High |

### When to Choose Each

```
Workspaces:
  ✅ Same infrastructure, different environments (dev/prod)
  ✅ Simple variable differences between environments
  ❌ Different infrastructure shapes per environment

Separate Configurations:
  ✅ Truly independent infrastructure pieces
  ✅ Different teams own different configs
  ❌ Need coordinated deployment across configs

Stacks:
  ✅ Multiple configs that must be deployed together
  ✅ Same topology deployed to many regions/environments
  ✅ Complex multi-component applications
  ❌ Simple single-config deployments
  ❌ No HCP Terraform access
```

---

## 🧩 Core Concepts

### Components

A **Component** is a reference to a Terraform configuration (like a module). Components are the building blocks of a Stack — each component manages a piece of the infrastructure.

```hcl
# In a .tfstack.hcl file
component "networking" {
  source = "./networking"

  inputs = {
    region      = var.region
    environment = var.environment
  }
}

component "compute" {
  source = "./compute"

  inputs = {
    vpc_id      = component.networking.vpc_id
    environment = var.environment
  }

  # Explicit dependency — compute waits for networking
  depends_on = [component.networking]
}
```

### Deployments

A **Deployment** is an instance of the Stack — like a workspace for the entire Stack. Each deployment gets its own state for each component.

```hcl
# In a .tfdeploy.hcl file
deployment "dev" {
  inputs = {
    region      = "us-east-1"
    environment = "dev"
  }
}

deployment "staging" {
  inputs = {
    region      = "us-east-1"
    environment = "staging"
  }
}

deployment "prod" {
  inputs = {
    region      = "us-west-2"
    environment = "prod"
  }
}
```

### Providers in Stacks

Providers in Stacks are declared differently — they use a `provider` block at the Stack level and are passed into components:

```hcl
# Provider declaration in .tfstack.hcl
provider "aws" "main" {
  config {
    region = var.region
  }
}

component "networking" {
  source = "./networking"

  providers = {
    aws = provider.aws.main
  }

  inputs = {
    environment = var.environment
  }
}
```

---

## 📄 File Types

Stacks introduce two new file types:

### `.tfstack.hcl` — Stack Definition

Defines the **components** (what to deploy) and **providers** for the Stack:

```
my-stack/
├── stack.tfstack.hcl      # Components and providers
├── variables.tfstack.hcl  # Stack-level input variables
└── outputs.tfstack.hcl    # Stack-level outputs
```

### `.tfdeploy.hcl` — Deployment Configuration

Defines the **deployments** (where/how to deploy the Stack):

```
my-stack/
└── deployments.tfdeploy.hcl   # Deployment instances
```

### Example Stack Structure

```
my-application-stack/
├── stack.tfstack.hcl          # Components: networking, compute, database
├── variables.tfstack.hcl      # region, environment, instance_type
├── outputs.tfstack.hcl        # app_url, database_endpoint
├── deployments.tfdeploy.hcl   # dev, staging, prod deployments
│
├── networking/                # Component: VPC, subnets, security groups
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── compute/                   # Component: EC2 instances, load balancer
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
└── database/                  # Component: RDS instance
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

---

## 🔧 Components

### Full Component Example

```hcl
# stack.tfstack.hcl

# Stack-level variables
variable "region" {
  type = string
}

variable "environment" {
  type = string
}

# Provider
provider "aws" "main" {
  config {
    region = var.region
  }
}

# Component 1: Networking (no dependencies)
component "networking" {
  source = "./networking"

  providers = {
    aws = provider.aws.main
  }

  inputs = {
    environment = var.environment
    vpc_cidr    = "10.0.0.0/16"
  }
}

# Component 2: Database (depends on networking)
component "database" {
  source = "./database"

  providers = {
    aws = provider.aws.main
  }

  inputs = {
    environment = var.environment
    subnet_ids  = component.networking.private_subnet_ids
    vpc_id      = component.networking.vpc_id
  }
}

# Component 3: Compute (depends on networking and database)
component "compute" {
  source = "./compute"

  providers = {
    aws = provider.aws.main
  }

  inputs = {
    environment     = var.environment
    subnet_ids      = component.networking.public_subnet_ids
    db_endpoint     = component.database.endpoint
    db_secret_arn   = component.database.secret_arn
  }
}
```

### Component Outputs

Components expose outputs that other components can reference:

```hcl
# In networking/outputs.tf (standard Terraform output)
output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

# In stack.tfstack.hcl — reference component outputs
component "compute" {
  inputs = {
    vpc_id     = component.networking.vpc_id      # ← component output reference
    subnet_ids = component.networking.private_subnet_ids
  }
}
```

---

## 🚀 Deployments

### Full Deployment Example

```hcl
# deployments.tfdeploy.hcl

deployment "dev" {
  inputs = {
    region      = "us-east-1"
    environment = "dev"
  }
}

deployment "staging" {
  inputs = {
    region      = "us-east-1"
    environment = "staging"
  }
}

deployment "prod-us" {
  inputs = {
    region      = "us-east-1"
    environment = "prod"
  }
}

deployment "prod-eu" {
  inputs = {
    region      = "eu-west-1"
    environment = "prod"
  }
}
```

### Deployment with Identity Tokens (OIDC)

For production use, deployments use identity tokens for dynamic provider credentials:

```hcl
# deployments.tfdeploy.hcl

identity_token "aws" {
  audience = ["aws.workload.identity"]
}

deployment "prod" {
  inputs = {
    region      = "us-east-1"
    environment = "prod"

    # Pass OIDC token for dynamic AWS credentials
    aws_role_arn = "arn:aws:iam::123456789012:role/terraform-stacks-role"
  }
}
```

---

## 💻 The `terraform stacks` CLI

> **Important**: The `terraform stacks` commands require HCP Terraform. They will not work with a local backend.

```bash
# Validate stack configuration
terraform stacks validate

# Plan all deployments in the stack
terraform stacks plan

# Plan a specific deployment
terraform stacks plan -deployment=dev

# Apply all deployments
terraform stacks apply

# Apply a specific deployment
terraform stacks apply -deployment=prod

# Show stack status
terraform stacks show

# List all deployments
terraform stacks deployments list
```

### Typical Stacks Workflow

```bash
# 1. Authenticate with HCP Terraform
terraform login

# 2. Validate the stack definition
terraform stacks validate

# 3. Plan changes (shows all deployments)
terraform stacks plan

# 4. Review the plan output
# HCP Terraform shows a plan per component per deployment

# 5. Apply (with approval in HCP Terraform UI or CLI)
terraform stacks apply
```

---

## 🔬 Hands-On Walkthrough

> **Prerequisites**: HCP Terraform account with Stacks enabled. Stacks may require a specific HCP Terraform tier — check the [HCP Terraform pricing page](https://www.hashicorp.com/products/terraform/pricing).

### Exercise: Conceptual Stack Design

Even without HCP Terraform access, you can practice designing a Stack. Consider this scenario:

**Scenario**: You manage a web application that needs to be deployed to `dev`, `staging`, and `prod` environments. Each environment needs:
- A VPC with public and private subnets
- An EC2 instance running the application
- An RDS database

**Design the Stack**:

1. **Identify the components**:
   - `networking` — VPC, subnets, security groups
   - `compute` — EC2 instance, load balancer
   - `database` — RDS instance

2. **Identify the dependencies**:
   - `compute` depends on `networking` (needs VPC/subnet IDs)
   - `database` depends on `networking` (needs VPC/subnet IDs)
   - `compute` depends on `database` (needs DB endpoint)

3. **Identify the deployments**:
   - `dev` — us-east-1, t3.micro instances
   - `staging` — us-east-1, t3.small instances
   - `prod` — us-east-1 + eu-west-1, t3.medium instances

4. **Sketch the `.tfstack.hcl`**:

```hcl
# Conceptual stack.tfstack.hcl

variable "region"        { type = string }
variable "environment"   { type = string }
variable "instance_type" { type = string }

provider "aws" "main" {
  config { region = var.region }
}

component "networking" {
  source    = "./networking"
  providers = { aws = provider.aws.main }
  inputs    = { environment = var.environment }
}

component "database" {
  source    = "./database"
  providers = { aws = provider.aws.main }
  inputs = {
    environment = var.environment
    subnet_ids  = component.networking.private_subnet_ids
    vpc_id      = component.networking.vpc_id
  }
}

component "compute" {
  source    = "./compute"
  providers = { aws = provider.aws.main }
  inputs = {
    environment   = var.environment
    instance_type = var.instance_type
    subnet_ids    = component.networking.public_subnet_ids
    db_endpoint   = component.database.endpoint
  }
}
```

5. **Sketch the `.tfdeploy.hcl`**:

```hcl
# Conceptual deployments.tfdeploy.hcl

deployment "dev" {
  inputs = {
    region        = "us-east-1"
    environment   = "dev"
    instance_type = "t3.micro"
  }
}

deployment "staging" {
  inputs = {
    region        = "us-east-1"
    environment   = "staging"
    instance_type = "t3.small"
  }
}

deployment "prod-us" {
  inputs = {
    region        = "us-east-1"
    environment   = "prod"
    instance_type = "t3.medium"
  }
}

deployment "prod-eu" {
  inputs = {
    region        = "eu-west-1"
    environment   = "prod"
    instance_type = "t3.medium"
  }
}
```

---

## ✅ When to Use Stacks

### Good Use Cases

- **Multi-region deployments**: Same application deployed to multiple AWS regions
- **Multi-environment pipelines**: dev → staging → prod with coordinated promotion
- **Platform teams**: Providing a "golden path" stack that product teams deploy
- **Complex applications**: Multiple interdependent Terraform configurations
- **Large-scale infrastructure**: Many environments that need consistent management

### Not a Good Fit

- **Simple single-config deployments**: Workspaces are simpler and sufficient
- **No HCP Terraform**: Stacks require HCP Terraform
- **Independent teams**: If teams own separate configs with no coordination needed
- **Learning Terraform**: Master core Terraform first (TF-100 through TF-400)

---

## ⚠️ Limitations and Considerations

1. **HCP Terraform required**: Stacks are not available in open-source Terraform or Terraform Enterprise (check your version)

2. **Terraform 1.13+**: Stacks were GA in Terraform 1.13 — ensure your HCP Terraform organization uses a compatible version

3. **New file types**: `.tfstack.hcl` and `.tfdeploy.hcl` are not valid in regular Terraform configurations — they are Stack-specific

4. **Provider configuration**: Providers in Stacks are declared differently than in regular Terraform — the `provider` block syntax is Stack-specific

5. **State management**: Each component in each deployment has its own state — this is more granular than workspaces

6. **Learning curve**: Stacks add significant complexity. Only adopt them when the coordination benefits outweigh the complexity cost

7. **Pricing**: Stacks may require a specific HCP Terraform tier — verify with HashiCorp's current pricing

---

## 🆕 New in Terraform 1.15: Stacks Improvements

Terraform 1.15 introduced several important improvements to Terraform Stacks that enhance the user experience and reliability:

### 1. Progress Events for Failed Plans

**What Changed**: Stacks now send progress events even when a plan fails, providing better UI integration and visibility into what went wrong.

**Why It Matters**: Previously, if a Stack plan failed, you might not get detailed progress information about which components succeeded before the failure. Now, HCP Terraform's UI can show you exactly where the failure occurred in the component dependency chain.

**Example Scenario**:

```hcl
# stack.tfstack.hcl
component "networking" {
  source = "./networking"
  inputs = {
    vpc_cidr = var.vpc_cidr
  }
}

component "database" {
  source = "./database"
  inputs = {
    vpc_id = component.networking.vpc_id
    # This might fail due to invalid configuration
    instance_class = "invalid.instance.type"
  }
}

component "compute" {
  source = "./compute"
  inputs = {
    vpc_id      = component.networking.vpc_id
    db_endpoint = component.database.endpoint
  }
}
```

**Before Terraform 1.15**:
- Plan fails on `database` component
- Limited visibility into which components completed successfully
- Harder to debug in the HCP Terraform UI

**After Terraform 1.15**:
- Plan fails on `database` component
- Progress events show that `networking` completed successfully
- Clear indication that `database` failed and `compute` was not attempted
- Better UI integration showing the exact failure point

**Best Practice**: When debugging Stack failures, check the HCP Terraform UI for the detailed progress events to understand the component execution order and failure point.

---

### 2. No-Op Plan/Apply Reporting

**What Changed**: Component instances now properly report when they have no changes (no-op operations), improving UI consistency especially with convergence destroy plans.

**Why It Matters**: This solves a UI inconsistency where components with no changes weren't clearly indicated, making it harder to understand the overall Stack state.

**Example Scenario**:

```hcl
# deployments.tfdeploy.hcl
deployment "dev" {
  inputs = {
    region      = "us-east-1"
    environment = "dev"
  }
}

deployment "staging" {
  inputs = {
    region      = "us-east-1"
    environment = "staging"
  }
}
```

**Scenario**: You update only the `dev` deployment's configuration:

```bash
# Plan the Stack
terraform stacks plan
```

**Before Terraform 1.15**:
- Components in `staging` deployment might not clearly show "no changes"
- UI could be confusing about which deployments/components are affected
- Convergence destroy plans had inconsistent reporting

**After Terraform 1.15**:
- Components with no changes explicitly report as "no-op"
- Clear distinction between:
  - Components with changes
  - Components with no changes (no-op)
  - Components not yet planned
- Convergence destroy plans show consistent no-op reporting

**Example Output**:
```
Planning Stack...

Deployment: dev
  Component: networking - 2 to add, 1 to change, 0 to destroy
  Component: database   - 0 to add, 1 to change, 0 to destroy
  Component: compute    - 0 to add, 0 to change, 0 to destroy (no-op)

Deployment: staging
  Component: networking - 0 to add, 0 to change, 0 to destroy (no-op)
  Component: database   - 0 to add, 0 to change, 0 to destroy (no-op)
  Component: compute    - 0 to add, 0 to change, 0 to destroy (no-op)
```

**Best Practice**: Use the no-op indicators to quickly identify which deployments and components are affected by your changes, making it easier to review large Stack plans.

---

### 3. Input Variable Validation for Stacks

**What Changed**: Terraform 1.15 adds support for input variable validation in Stack configurations, bringing the same validation capabilities available in regular Terraform to Stacks.

**Why It Matters**: You can now enforce constraints on Stack-level variables, catching configuration errors early before deployment.

**Syntax**:

```hcl
# variables.tfstack.hcl

variable "environment" {
  type        = string
  description = "Deployment environment"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "region" {
  type        = string
  description = "AWS region for deployment"

  validation {
    condition     = can(regex("^(us|eu|ap)-(east|west|central|south|north|northeast|southeast)-[1-9]$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-2)."
  }
}

variable "instance_count" {
  type        = number
  description = "Number of instances to deploy"
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}
```

**Using Validated Variables in Deployments**:

```hcl
# deployments.tfdeploy.hcl

deployment "dev" {
  inputs = {
    environment    = "dev"           # ✅ Valid
    region         = "us-east-1"     # ✅ Valid
    instance_count = 2               # ✅ Valid
    vpc_cidr       = "10.0.0.0/16"   # ✅ Valid
  }
}

deployment "invalid-example" {
  inputs = {
    environment    = "production"    # ❌ Fails validation - not in allowed list
    region         = "invalid-region" # ❌ Fails validation - invalid format
    instance_count = 15              # ❌ Fails validation - exceeds maximum
    vpc_cidr       = "not-a-cidr"    # ❌ Fails validation - invalid CIDR
  }
}
```

**Validation Error Example**:

```bash
$ terraform stacks validate

Error: Invalid value for variable

  on deployments.tfdeploy.hcl line 15, in deployment "invalid-example":
  15:     environment = "production"

Environment must be dev, staging, or prod.

Error: Invalid value for variable

  on deployments.tfdeploy.hcl line 16, in deployment "invalid-example":
  16:     region = "invalid-region"

Region must be a valid AWS region format (e.g., us-east-1, eu-west-2).
```

**Advanced Validation Examples**:

```hcl
# Cross-variable validation
variable "enable_multi_az" {
  type    = bool
  default = false
}

variable "availability_zones" {
  type = list(string)

  validation {
    condition = (
      !var.enable_multi_az ||
      length(var.availability_zones) >= 2
    )
    error_message = "When enable_multi_az is true, at least 2 availability zones must be specified."
  }
}

# Complex validation with multiple conditions
variable "instance_type" {
  type = string

  validation {
    condition = (
      can(regex("^t[2-3]\\.", var.instance_type)) ||
      can(regex("^m[5-6]\\.", var.instance_type)) ||
      can(regex("^c[5-6]\\.", var.instance_type))
    )
    error_message = "Instance type must be from t2, t3, m5, m6, c5, or c6 families."
  }
}

# Validation with environment-specific rules
variable "backup_retention_days" {
  type = number

  validation {
    condition = (
      (var.environment == "prod" && var.backup_retention_days >= 30) ||
      (var.environment != "prod" && var.backup_retention_days >= 7)
    )
    error_message = "Production requires 30+ days retention, non-production requires 7+ days."
  }
}
```

**Best Practices for Stack Variable Validation**:

1. **Validate Early**: Add validation rules to catch errors before deployment
2. **Clear Error Messages**: Provide helpful error messages that explain what's wrong and how to fix it
3. **Environment-Specific Rules**: Use validation to enforce different requirements for dev vs prod
4. **Format Validation**: Validate formats (CIDR blocks, regions, etc.) to prevent typos
5. **Range Validation**: Enforce reasonable limits on numeric values
6. **Dependency Validation**: Validate that related variables are consistent with each other

**Common Validation Patterns**:

```hcl
# Enum validation (allowed values)
validation {
  condition     = contains(["small", "medium", "large"], var.size)
  error_message = "Size must be small, medium, or large."
}

# Regex pattern matching
validation {
  condition     = can(regex("^[a-z0-9-]+$", var.name))
  error_message = "Name must contain only lowercase letters, numbers, and hyphens."
}

# Numeric range
validation {
  condition     = var.port >= 1024 && var.port <= 65535
  error_message = "Port must be between 1024 and 65535."
}

# CIDR validation
validation {
  condition     = can(cidrhost(var.cidr, 0))
  error_message = "Must be a valid CIDR block."
}

# List length validation
validation {
  condition     = length(var.tags) <= 50
  error_message = "Maximum of 50 tags allowed."
}

# Conditional validation
validation {
  condition = (
    !var.enable_feature ||
    var.feature_config != null
  )
  error_message = "feature_config is required when enable_feature is true."
}
```

---

### Summary of Terraform 1.15 Stacks Improvements

| Feature | Benefit | Use Case |
|---------|---------|----------|
| **Progress Events on Failure** | Better debugging and UI visibility | Understanding which components succeeded before a failure |
| **No-Op Reporting** | Clearer plan output and UI consistency | Quickly identifying affected components in large Stacks |
| **Input Variable Validation** | Early error detection and enforcement | Preventing invalid configurations before deployment |

**Migration Notes**:

- These improvements are **backward compatible** — existing Stacks work without changes
- Variable validation is **optional** — add it incrementally to existing Stacks
- Progress events and no-op reporting are **automatic** — no configuration needed

**Recommended Actions**:

1. **Add Variable Validation**: Review your Stack variables and add validation rules for critical inputs
2. **Update Documentation**: Document the validation rules so deployment authors understand the constraints
3. **Test Validation**: Create test deployments with invalid values to verify your validation rules work correctly
4. **Monitor Progress Events**: Use the improved progress events in HCP Terraform UI to debug plan failures more effectively

---

## 📝 Checkpoint Quiz

### Question 1: What is a Terraform Stack?
**What is the primary purpose of Terraform Stacks?**

A) A replacement for Terraform modules  
B) A way to manage multiple Terraform configurations as a coordinated unit  
C) A new type of Terraform state file  
D) A replacement for workspaces in all scenarios

<details>
<summary>Click to reveal answer</summary>

**Answer: B) A way to manage multiple Terraform configurations as a coordinated unit**

Stacks allow you to define multiple components (Terraform configurations) and deploy them together as a unit across multiple deployments (environments/regions), with HCP Terraform handling the coordination.
</details>

---

### Question 2: File Types
**Which file type defines the components and providers in a Terraform Stack?**

A) `.tfstack.hcl`  
B) `.tfdeploy.hcl`  
C) `.tfvars`  
D) `.tfmodule.hcl`

<details>
<summary>Click to reveal answer</summary>

**Answer: A) `.tfstack.hcl`**

- `.tfstack.hcl` — defines components, providers, and Stack-level variables/outputs
- `.tfdeploy.hcl` — defines deployments (instances of the Stack)
</details>

---

### Question 3: Requirements
**What is required to use Terraform Stacks?**

A) Terraform 1.10+ and any backend  
B) HCP Terraform and Terraform 1.13+  
C) Terraform Enterprise only  
D) Any Terraform version with a remote backend

<details>
<summary>Click to reveal answer</summary>

**Answer: B) HCP Terraform and Terraform 1.13+**

Stacks require HCP Terraform (not available in open-source Terraform) and were GA in Terraform 1.13.
</details>

---

### Question 4: Deployments
**In Terraform Stacks, what is a "Deployment"?**

A) A single `terraform apply` operation  
B) An instance of the Stack (like a workspace for the entire Stack)  
C) A component within the Stack  
D) A provider configuration

<details>
<summary>Click to reveal answer</summary>

**Answer: B) An instance of the Stack (like a workspace for the entire Stack)**

A Deployment is an instance of the Stack with specific input values — for example, `dev`, `staging`, and `prod` deployments of the same Stack definition.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [Terraform Stacks Overview](https://developer.hashicorp.com/terraform/language/stacks)
- [`.tfstack.hcl` Reference](https://developer.hashicorp.com/terraform/language/stacks/reference/tfstack)
- [`.tfdeploy.hcl` Reference](https://developer.hashicorp.com/terraform/language/stacks/reference/tfdeploy)
- [terraform stacks CLI](https://developer.hashicorp.com/terraform/cli/commands/stacks)
- [HCP Terraform Stacks](https://developer.hashicorp.com/terraform/cloud-docs/stacks)

### Related Courses
- **Previous**: [TF-404: Sentinel Policy as Code](../TF-404-sentinel-policies/README.md)
- **Related**: [TF-402: Remote Runs & VCS Integration](../TF-402-remote-runs/README.md) — prerequisite concepts
- **Related**: [TF-305: Workspaces & Remote State](../../TF-300-advanced/TF-305-workspaces-remote-state/README.md) — compare with workspaces

---

*Part of the [Hashi-Training](../../README.md) curriculum — TF-400: HCP Terraform & Enterprise Features*