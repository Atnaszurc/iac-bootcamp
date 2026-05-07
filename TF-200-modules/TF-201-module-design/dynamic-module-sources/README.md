# Dynamic Module Sources with Variables and Locals

**New in Terraform 1.15+**

Objective: Learn how to use variables and locals in module `source` and `version` attributes for dynamic module sourcing and version management.

## Table of Contents

1. [Overview](#overview)
2. [Why Dynamic Module Sources?](#why-dynamic-module-sources)
3. [Syntax](#syntax)
4. [Use Cases](#use-cases)
5. [Instructions](#instructions)
6. [Best Practices](#best-practices)
7. [Limitations](#limitations)

## Overview

Terraform 1.15 introduces a powerful new capability: using variables and locals in module `source` and `version` attributes. This enables dynamic module sourcing, environment-specific versioning, and centralized version management - features that were previously impossible.

### What's New

**Before Terraform 1.15** (Static only):
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"  # Must be literal string
  version = "5.0.0"                          # Must be literal string
}
```

**Terraform 1.15+** (Dynamic):
```hcl
variable "module_version" {
  default = "5.0.0"
}

module "vpc" {
  source  = var.module_source    # Can use variables!
  version = var.module_version   # Can use variables!
}
```

## Why Dynamic Module Sources?

### Problems This Solves

1. **Environment-Specific Versions**: Different module versions per environment
2. **Centralized Version Management**: Single source of truth for module versions
3. **Dynamic Module Selection**: Choose modules based on conditions
4. **CI/CD Integration**: Pass module versions from pipeline variables
5. **Testing**: Easy switching between module versions for testing
6. **Multi-Tenancy**: Different module sources per tenant/customer

### Benefits

- ✅ **Flexibility**: Dynamic module selection based on variables
- ✅ **Consistency**: Centralized version management
- ✅ **Automation**: CI/CD-driven module versioning
- ✅ **Testing**: Easy version switching for testing
- ✅ **Multi-Environment**: Different versions per environment
- ✅ **Maintainability**: Update versions in one place

## Syntax

### Using Variables

```hcl
variable "module_source" {
  description = "Source of the module"
  type        = string
}

variable "module_version" {
  description = "Version of the module"
  type        = string
}

module "example" {
  source  = var.module_source
  version = var.module_version
  
  # Module inputs...
}
```

### Using Locals

```hcl
locals {
  module_source  = "terraform-aws-modules/vpc/aws"
  module_version = "5.0.0"
}

module "example" {
  source  = local.module_source
  version = local.module_version
  
  # Module inputs...
}
```

### Conditional Module Sources

```hcl
locals {
  module_source = var.environment == "prod" ? 
    "terraform-aws-modules/vpc/aws" : 
    "./modules/vpc-dev"
}

module "vpc" {
  source = local.module_source
  # ...
}
```

## Use Cases

### Use Case 1: Environment-Specific Versions

```hcl
# versions.tf
locals {
  module_versions = {
    dev     = "4.0.0"  # Older stable version for dev
    staging = "5.0.0"  # Latest for staging
    prod    = "4.5.0"  # Proven version for prod
  }
  
  vpc_version = local.module_versions[var.environment]
}

# main.tf
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = local.vpc_version
  
  name = "${var.environment}-vpc"
  # ...
}
```

### Use Case 2: Centralized Version Management

```hcl
# versions.tf - Single source of truth
locals {
  module_versions = {
    vpc        = "5.0.0"
    security   = "4.2.0"
    compute    = "3.1.0"
    database   = "2.5.0"
  }
}

# main.tf
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = local.module_versions.vpc
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = local.module_versions.security
}

module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = local.module_versions.compute
}
```

### Use Case 3: Dynamic Module Selection

```hcl
locals {
  # Choose module based on cloud provider
  vpc_module_source = {
    aws   = "terraform-aws-modules/vpc/aws"
    azure = "Azure/network/azurerm"
    gcp   = "terraform-google-modules/network/google"
  }
  
  selected_vpc_module = local.vpc_module_source[var.cloud_provider]
}

module "vpc" {
  source = local.selected_vpc_module
  # ...
}
```

### Use Case 4: Local vs Remote Modules

```hcl
locals {
  # Use local modules in development, remote in production
  use_local_modules = var.environment == "dev"
  
  vpc_source = local.use_local_modules ? 
    "./modules/vpc" : 
    "terraform-aws-modules/vpc/aws"
}

module "vpc" {
  source  = local.vpc_source
  version = local.use_local_modules ? null : "5.0.0"
  # ...
}
```

### Use Case 5: CI/CD Integration

```hcl
# Pass from CI/CD pipeline
variable "module_version" {
  description = "Module version from CI/CD"
  type        = string
  default     = "5.0.0"  # Fallback
}

variable "use_canary_modules" {
  description = "Use canary module versions"
  type        = bool
  default     = false
}

locals {
  # Canary testing in CI/CD
  vpc_version = var.use_canary_modules ? 
    "5.1.0-beta" : 
    var.module_version
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = local.vpc_version
}
```

### Use Case 6: Multi-Tenant Configuration

```hcl
variable "tenant_id" {
  description = "Tenant identifier"
  type        = string
}

locals {
  # Different module sources per tenant
  tenant_module_config = {
    tenant_a = {
      source  = "git::https://github.com/tenant-a/modules.git//vpc"
      version = "1.0.0"
    }
    tenant_b = {
      source  = "git::https://github.com/tenant-b/modules.git//vpc"
      version = "2.0.0"
    }
    default = {
      source  = "terraform-aws-modules/vpc/aws"
      version = "5.0.0"
    }
  }
  
  tenant_config = lookup(
    local.tenant_module_config,
    var.tenant_id,
    local.tenant_module_config.default
  )
}

module "vpc" {
  source  = local.tenant_config.source
  version = local.tenant_config.version
}
```

## Instructions

### Task 1: Basic Variable-Driven Module Source

Create a `variables.tf`:
```hcl
variable "module_source" {
  description = "Source path for the configuration module"
  type        = string
  default     = "./modules/versioned-config"
}

variable "module_version" {
  description = "Version of the module (for registry modules)"
  type        = string
  default     = "1.0.0"
}
```

Create a `main.tf`:
```hcl
terraform {
  required_version = ">= 1.15.0"
}

module "config" {
  source = var.module_source
  
  app_name    = "my-app"
  environment = "dev"
}
```

### Task 2: Environment-Specific Versioning

```hcl
variable "environment" {
  type = string
}

locals {
  # Version strategy per environment
  module_versions = {
    dev     = "1.0.0"  # Stable
    staging = "1.1.0"  # Latest
    prod    = "1.0.5"  # Proven
  }
  
  config_version = local.module_versions[var.environment]
}

module "config" {
  source  = "registry.terraform.io/myorg/config/local"
  version = local.config_version
  
  environment = var.environment
}
```

### Task 3: Conditional Module Selection

```hcl
variable "use_local_development" {
  description = "Use local modules for development"
  type        = bool
  default     = false
}

locals {
  module_source = var.use_local_development ? 
    "./modules/versioned-config" : 
    "registry.terraform.io/myorg/config/local"
    
  module_version = var.use_local_development ? 
    null :  # Local modules don't have versions
    "1.0.0"
}

module "config" {
  source  = local.module_source
  version = local.module_version
  
  app_name = "my-app"
}
```

### Task 4: Centralized Version Management

Create `module-versions.tf`:
```hcl
locals {
  # Central registry of all module versions
  module_registry = {
    config = {
      source  = "./modules/versioned-config"
      version = "1.0.0"
    }
    network = {
      source  = "terraform-aws-modules/vpc/aws"
      version = "5.0.0"
    }
    compute = {
      source  = "terraform-aws-modules/ec2-instance/aws"
      version = "5.2.0"
    }
  }
}
```

Use in `main.tf`:
```hcl
module "config" {
  source  = local.module_registry.config.source
  version = local.module_registry.config.version
  
  app_name = "my-app"
}

module "network" {
  source  = local.module_registry.network.source
  version = local.module_registry.network.version
  
  name = "my-vpc"
}
```

### Task 5: Testing with Version Override

```hcl
variable "override_module_versions" {
  description = "Override module versions for testing"
  type        = map(string)
  default     = {}
}

locals {
  default_versions = {
    config  = "1.0.0"
    network = "5.0.0"
  }
  
  # Merge defaults with overrides
  module_versions = merge(
    local.default_versions,
    var.override_module_versions
  )
}

module "config" {
  source  = "./modules/versioned-config"
  version = local.module_versions.config
}
```

Test with:
```bash
# Use default versions
terraform plan

# Override for testing
terraform plan -var='override_module_versions={"config":"1.1.0-beta"}'
```

## Best Practices

### 1. Centralize Version Management

✅ **Good** - Single source of truth:
```hcl
# versions.tf
locals {
  module_versions = {
    vpc      = "5.0.0"
    security = "4.2.0"
  }
}

# main.tf
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = local.module_versions.vpc
}
```

❌ **Avoid** - Scattered versions:
```hcl
module "vpc1" {
  version = "5.0.0"
}

module "vpc2" {
  version = "5.0.0"  # Duplicate!
}
```

### 2. Document Version Strategy

```hcl
locals {
  module_versions = {
    # VPC module - using 5.0.0 for stability
    # Tested: 2024-01-15
    # Next upgrade: 5.1.0 (planned for Q2)
    vpc = "5.0.0"
    
    # Security group - latest stable
    # Auto-update: patch versions only
    security = "~> 4.2.0"
  }
}
```

### 3. Use Validation

```hcl
variable "module_version" {
  type = string
  
  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.module_version))
    error_message = "Module version must be in semver format (x.y.z)"
  }
}
```

### 4. Provide Defaults

```hcl
variable "module_source" {
  description = "Module source path"
  type        = string
  default     = "./modules/config"  # Safe default
}
```

### 5. Environment-Specific Overrides

```hcl
# terraform.tfvars (dev)
module_versions = {
  vpc = "4.0.0"  # Older stable for dev
}

# terraform.tfvars (prod)
module_versions = {
  vpc = "5.0.0"  # Latest proven for prod
}
```

### 6. Use Descriptive Variable Names

✅ **Good**:
```hcl
variable "vpc_module_version" {
  description = "Version of the VPC module"
}
```

❌ **Avoid**:
```hcl
variable "version" {  # Too generic
}
```

## Limitations

### 1. Init-Time Evaluation Constraint ⚠️

**Critical Limitation**: While Terraform 1.15 supports variables and locals in module sources, they must be evaluable during `terraform init`, which has significant restrictions.

**❌ This will FAIL during init** (dynamic expressions):
```hcl
locals {
  # Conditional expression - NOT evaluable during init
  module_source = var.use_local ? "./modules/config" : "registry.terraform.io/myorg/config"
}

module "config" {
  source = local.module_source  # ERROR during terraform init
}
```

**Error message**:
```
Only literal values and const variables can be evaluated during init.
```

**✅ This WORKS** (static paths):
```hcl
module "config" {
  source = "./modules/config"  # Static path works
  
  # Pass dynamic configuration as inputs instead
  use_local_config = var.use_local
}
```

**Best Practice**: Use static module sources and pass dynamic configuration as module inputs:

```hcl
# Instead of dynamic sources, use static source with dynamic config
module "config" {
  source = "./modules/config"
  
  # Module handles logic internally based on inputs
  environment = var.environment
  version_tag = var.environment == "prod" ? "1.0.0" : "1.1.0"
}
```

### 2. Module Source Must Be Known at Plan Time

```hcl
# ❌ This won't work - depends on resource output
module "config" {
  source = data.external.module_source.result.source
}

# ✅ This works - depends on input variable with default
module "config" {
  source = var.module_source
}
```

### 3. Cannot Use Resource Outputs

```hcl
# ❌ Not allowed
module "config" {
  source = aws_s3_bucket.modules.bucket
}

# ✅ Use variables or locals with literal values
module "config" {
  source = var.module_source
}
```

### 4. Version Constraints Still Apply

```hcl
variable "module_version" {
  default = "5.0.0"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = var.module_version  # Must be valid version string
}
```

### 5. Local Modules Don't Have Versions

```hcl
module "local_config" {
  source  = "./modules/config"
  version = "1.0.0"  # ❌ Ignored for local modules
}
```

### Practical Implications

Given the init-time evaluation constraint, the most practical use cases for dynamic module sources are:

1. **Environment-specific versions** (version attribute, not source)
2. **Centralized version management** (version attribute)
3. **CI/CD version overrides** (version attribute with variables)

For truly dynamic module selection, consider:
- Using separate Terraform configurations per environment
- Using workspace-specific `.tfvars` files with different static sources
- Structuring modules to handle variations internally

## Summary

Dynamic module sources in Terraform 1.15+ enable:

- ✅ **Environment-specific module versions**
- ✅ **Centralized version management**
- ✅ **Dynamic module selection**
- ✅ **CI/CD integration**
- ✅ **Testing flexibility**
- ✅ **Multi-tenant configurations**

Use this feature to:
- Manage module versions consistently
- Enable environment-specific configurations
- Integrate with CI/CD pipelines
- Simplify testing and upgrades
- Support multi-tenant architectures

---

**Version Requirements**: Terraform >= 1.15.0  
**Related Topics**: [Module Design](../README.md), [Variables](../../../TF-100-fundamentals/TF-102-variables-loops/README.md)  
**Next**: [Advanced Module Patterns](../../TF-202-advanced-patterns/README.md)