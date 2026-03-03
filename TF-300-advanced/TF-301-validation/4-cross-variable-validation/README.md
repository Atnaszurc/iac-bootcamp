# Cross-Variable Validation (Terraform 1.9+)

## Overview

**Terraform 1.9** expanded variable validation to allow validation conditions to **reference other variables** — not just the variable being validated. This enables powerful business-logic enforcement directly in your variable definitions, catching configuration errors at `terraform plan` time before any infrastructure is touched.

> **Version Note**: Cross-variable validation (referencing `var.<other>` in a validation block) requires **Terraform 1.9+**. Prior to 1.9, validation conditions could only reference the variable itself (`var.<self>`).

---

## What Changed in Terraform 1.9

### Before 1.9 — Self-Reference Only

```hcl
# ✅ VALID before 1.9: only references var.instance_count (self)
variable "instance_count" {
  type = number
  validation {
    condition     = var.instance_count >= 1
    error_message = "Must have at least 1 instance."
  }
}

# ❌ INVALID before 1.9: references var.environment (another variable)
variable "instance_count" {
  type = number
  validation {
    condition     = var.environment == "prod" ? var.instance_count >= 3 : var.instance_count >= 1
    error_message = "Production requires at least 3 instances."
  }
}
```

### After 1.9 — Cross-Variable References Allowed

```hcl
# ✅ VALID in 1.9+: can reference any other variable
variable "instance_count" {
  type = number
  validation {
    condition     = var.environment == "prod" ? var.instance_count >= 3 : var.instance_count >= 1
    error_message = "Production requires at least 3 instances; other environments require at least 1."
  }
}
```

---

## Key Rules

| Rule | Detail |
|------|--------|
| **Can reference** | Any other `var.<name>` in the same module |
| **Cannot reference** | `local.*`, `resource.*`, `data.*`, `module.*` |
| **Evaluation order** | All variables are evaluated before validations run — order of definition doesn't matter |
| **Circular references** | Not allowed — Terraform detects and rejects them |
| **Null safety** | If the referenced variable has no value yet, validation may fail — use `try()` or `can()` defensively |

---

## Practical Examples

### Example 1: Environment-Driven Instance Count

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "instance_count" {
  type        = number
  description = "Number of application instances"

  validation {
    # Terraform 1.9+: reference var.environment in this validation
    condition     = var.environment == "prod" ? var.instance_count >= 3 : var.instance_count >= 1
    error_message = "Production requires at least 3 instances for HA; other environments require at least 1."
  }
}
```

**Test it**:
```bash
# This fails: prod with only 1 instance
terraform plan -var="environment=prod" -var="instance_count=1"
# Error: Production requires at least 3 instances for HA; other environments require at least 1.

# This passes: prod with 3 instances
terraform plan -var="environment=prod" -var="instance_count=3"
```

---

### Example 2: Disk Size Enforcement by Environment

```hcl
variable "environment" {
  type = string
}

variable "disk_size_gb" {
  type        = number
  description = "Root disk size in GB"

  validation {
    condition     = var.environment == "prod" ? var.disk_size_gb >= 50 : var.disk_size_gb >= 10
    error_message = "Production disks must be at least 50 GB; other environments at least 10 GB."
  }

  validation {
    condition     = var.disk_size_gb <= 2000
    error_message = "Disk size cannot exceed 2000 GB."
  }
}
```

---

### Example 3: Backup Retention Enforcement

```hcl
variable "enable_backups" {
  type        = bool
  description = "Whether to enable automated backups"
  default     = false
}

variable "backup_retention_days" {
  type        = number
  description = "Number of days to retain backups (0 = disabled)"
  default     = 0

  validation {
    # If backups are enabled, retention must be at least 7 days
    condition     = var.enable_backups ? var.backup_retention_days >= 7 : var.backup_retention_days >= 0
    error_message = "When backups are enabled, retention must be at least 7 days."
  }

  validation {
    condition     = var.backup_retention_days <= 365
    error_message = "Backup retention cannot exceed 365 days."
  }
}
```

---

### Example 4: Multi-Variable Consistency Check

```hcl
variable "environment" {
  type = string
}

variable "region" {
  type        = string
  description = "Deployment region"
}

variable "enable_multi_region" {
  type        = bool
  description = "Whether to deploy across multiple regions"
  default     = false

  validation {
    # Multi-region is only allowed in production
    condition     = var.enable_multi_region ? var.environment == "prod" : true
    error_message = "Multi-region deployment is only allowed in the 'prod' environment."
  }
}

variable "replica_count" {
  type        = number
  description = "Number of read replicas"
  default     = 0

  validation {
    # Replicas require multi-region to be enabled
    condition     = var.replica_count > 0 ? var.enable_multi_region == true : true
    error_message = "Read replicas require multi-region deployment to be enabled."
  }

  validation {
    # Prod must have replicas if multi-region is enabled
    condition     = (var.environment == "prod" && var.enable_multi_region) ? var.replica_count >= 1 : true
    error_message = "Production multi-region deployments must have at least 1 read replica."
  }
}
```

---

## Hands-On Lab

The `example/` directory contains a working Terraform configuration demonstrating cross-variable validation with the `local` provider (no cloud account needed).

### Lab Setup

```bash
cd example/
terraform init
```

### Lab Exercises

**Exercise 1 — Trigger a validation failure**:
```bash
# This should FAIL: prod environment with only 1 instance
terraform plan \
  -var="environment=prod" \
  -var="instance_count=1" \
  -var="disk_size_gb=100"
```

**Exercise 2 — Fix the configuration**:
```bash
# This should PASS: prod with 3 instances and 50+ GB disk
terraform plan \
  -var="environment=prod" \
  -var="instance_count=3" \
  -var="disk_size_gb=100"
```

**Exercise 3 — Dev environment (relaxed rules)**:
```bash
# This should PASS: dev with 1 instance and 10 GB disk
terraform plan \
  -var="environment=dev" \
  -var="instance_count=1" \
  -var="disk_size_gb=10"
```

**Exercise 4 — Backup consistency**:
```bash
# This should FAIL: backups enabled but retention too low
terraform plan \
  -var="environment=dev" \
  -var="instance_count=1" \
  -var="disk_size_gb=10" \
  -var="enable_backups=true" \
  -var="backup_retention_days=3"
```

**Exercise 5 — Apply a valid configuration**:
```bash
# Full valid configuration
terraform apply \
  -var="environment=staging" \
  -var="instance_count=2" \
  -var="disk_size_gb=20" \
  -var="enable_backups=true" \
  -var="backup_retention_days=14"
```

---

## Comparison: Before and After 1.9

| Scenario | Before 1.9 | After 1.9 (1.9+) |
|----------|-----------|-----------------|
| Validate `var.count >= 1` | ✅ Works | ✅ Works |
| Validate `var.env == "prod" ? var.count >= 3 : true` | ❌ Error | ✅ Works |
| Reference `local.something` in validation | ❌ Error | ❌ Still not allowed |
| Reference `data.source.attr` in validation | ❌ Error | ❌ Still not allowed |
| Reference `resource.name.attr` in validation | ❌ Error | ❌ Still not allowed |

---

## When to Use Cross-Variable Validation

✅ **Good use cases**:
- Environment-specific resource sizing (prod needs more capacity)
- Feature flag consistency (feature X requires feature Y)
- Compliance rules (prod must have backups, encryption, HA)
- Mutually exclusive options (can't enable both A and B)
- Dependent configuration (if X is set, Y must also be set)

❌ **Not suitable for**:
- Validating against live infrastructure (use `check` blocks instead)
- Complex business logic that depends on data sources
- Validation that requires API calls

---

## Related Topics

- **[1-variable-conditions/](../1-variable-conditions/README.md)** — Basic validation syntax
- **[2-advanced-functions/](../2-advanced-functions/README.md)** — `try()` and `can()` for safe validation
- **[3-sensitive-values/](../3-sensitive-values/README.md)** — Sensitive variables and `nonsensitive()`
- **[TF-302: Check Blocks](../../TF-302-conditions-checks/README.md)** — Runtime validation with `check` blocks

---

*Terraform Version: 1.9+ (cross-variable validation)*  
*Last Updated: 2026-03-01*