:
- What to use instead
- When it will be removed (version number)
- Why it's being deprecated (optional but helpful)

### Example Patterns

**Pattern 1: Simple Rename**
```hcl
variable "old_name" {
  type       = string
  deprecated = "Use 'new_name' instead. Will be removed in v2.0.0"
}

variable "new_name" {
  type = string
}
```

**Pattern 2: Type Change**
```hcl
variable "port" {
  type       = string
  deprecated = "Use 'port_number' (number type) instead. String ports are deprecated."
}

variable "port_number" {
  type    = number
  default = 8080
}
```

**Pattern 3: Structural Change**
```hcl
variable "server_name" {
  type       = string
  deprecated = "Use 'server_config.name' instead. Flat variables are being replaced with structured config."
}

variable "server_config" {
  type = object({
    name = string
    port = number
  })
}
```

## Best Practices

### 1. Write Clear Deprecation Messages

✅ **Good**:
```hcl
deprecated = "Use 'instance_type' instead. This variable will be removed in v2.0.0"
```

❌ **Bad**:
```hcl
deprecated = "Deprecated"
```

### 2. Provide Migration Timeline

Include version information so users know when to migrate:
```hcl
deprecated = "Use 'new_var' instead. Deprecated in v1.5.0, will be removed in v2.0.0"
```

### 3. Maintain Backward Compatibility

Keep deprecated variables working during the transition period:
```hcl
locals {
  # Use new variable if set, otherwise fall back to deprecated one
  effective_value = var.new_var != null ? var.new_var : var.old_var
}
```

### 4. Document Migration Path

Create a MIGRATION.md file with:
- List of deprecated variables/outputs
- What to use instead
- Code examples
- Timeline for removal

### 5. Version Your Modules

Use semantic versioning:
- **Minor version** (1.5.0): Add deprecation warnings
- **Major version** (2.0.0): Remove deprecated variables

### 6. Test Deprecation Warnings

Ensure warnings appear correctly:
```bash
terraform plan 2>&1 | grep -i "deprecated"
```

### 7. Gradual Migration

Don't deprecate everything at once:
1. Deprecate in version X.Y.0
2. Give users 2-3 minor versions to migrate
3. Remove in version (X+1).0.0

## Common Patterns

### Pattern: Renaming for Clarity

```hcl
# Old name was unclear
variable "size" {
  type       = string
  deprecated = "Use 'instance_size' for clarity. Will be removed in v2.0.0"
}

# New name is more specific
variable "instance_size" {
  type        = string
  description = "Size of the compute instance"
}
```

### Pattern: Consolidating Variables

```hcl
# Old: Multiple separate variables
variable "server_name" {
  type       = string
  deprecated = "Use 'server_config.name' instead"
}

variable "server_port" {
  type       = number
  deprecated = "Use 'server_config.port' instead"
}

# New: Single structured variable
variable "server_config" {
  type = object({
    name = string
    port = number
  })
  description = "Complete server configuration"
}
```

### Pattern: Changing Defaults

```hcl
# Old variable with old default
variable "old_region" {
  type       = string
  default    = "us-east-1"
  deprecated = "Use 'region' instead. Default changed to us-west-2"
}

# New variable with new default
variable "region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region for resources"
}
```

## Real-World Example

Here's a complete example showing module evolution:

```hcl
# variables.tf - Module v1.5.0 (with deprecations)

# === DEPRECATED VARIABLES ===

variable "vm_type" {
  type       = string
  default    = "small"
  deprecated = "Use 'compute_config.instance_type' instead. Will be removed in v2.0.0"
}

variable "vm_count" {
  type       = number
  default    = 1
  deprecated = "Use 'compute_config.count' instead. Will be removed in v2.0.0"
}

variable "enable_monitoring" {
  type       = bool
  default    = false
  deprecated = "Use 'compute_config.monitoring.enabled' instead. Will be removed in v2.0.0"
}

# === NEW VARIABLES ===

variable "compute_config" {
  type = object({
    instance_type = string
    count         = number
    monitoring = object({
      enabled  = bool
      interval = number
    })
  })
  description = "Complete compute configuration"
  default = {
    instance_type = "t3.micro"
    count         = 1
    monitoring = {
      enabled  = false
      interval = 60
    }
  }
}

# === BACKWARD COMPATIBILITY LOGIC ===

locals {
  # Use new config if provided, otherwise build from old variables
  effective_config = var.compute_config != null ? var.compute_config : {
    instance_type = var.vm_type
    count         = var.vm_count
    monitoring = {
      enabled  = var.enable_monitoring
      interval = 60
    }
  }
}
```

## Testing Your Deprecations

Create a test file to verify warnings appear:

```hcl
# test_deprecation.tfvars
old_instance_type = "t2.large"  # Should trigger warning
env               = "prod"       # Should trigger warning
```

Run:
```bash
terraform plan -var-file="test_deprecation.tfvars"
```

Expected output should include warnings about deprecated variables.
## Limitations

### Root Module Restriction

⚠️ **Important**: The `deprecated` attribute only works in **child modules**, not in root modules.

**❌ This will NOT work** (root module):
```hcl
# Root module variables.tf
variable "old_var" {
  type       = string
  deprecated = "Use new_var instead"  # ERROR: Root module outputs cannot be deprecated
}
```

**Error message**:
```
Root module outputs cannot be deprecated, as there is no higher-level module to inform of the deprecation.
```

**✅ This WORKS** (child module):
```hcl
# modules/my-module/variables.tf
variable "old_var" {
  type       = string
  deprecated = "Use new_var instead"  # OK: Works in child modules
}
```

### Workaround for Root Modules

For root modules, use description warnings instead:

```hcl
# Root module variables.tf
variable "old_var" {
  type        = string
  description = "⚠️ DEPRECATED: Use new_var instead. Will be removed in v2.0.0"
}

variable "old_output" {
  description = "⚠️ DEPRECATED: Use new_output instead. Will be removed in v2.0.0"
  value       = "some_value"
}
```

This provides visual warnings in documentation and IDE tooltips, even though it won't generate runtime warnings.


## Summary

The `deprecated` attribute in Terraform 1.15+ provides a professional way to evolve your infrastructure code:

- ✅ **Communicate changes** clearly to users
- ✅ **Maintain compatibility** during transitions
- ✅ **Guide migrations** with helpful messages
- ✅ **Plan removals** with version timelines
- ✅ **Document evolution** inline with code

Use deprecation warnings to make your modules more maintainable and user-friendly!

---

**Version Requirements**: Terraform >= 1.15.0  
**Related Topics**: [Variables](../1-variables/README.md), [Module Design](../../../TF-200-modules/TF-201-module-design/README.md)  
**Next**: [Section 2: Loops](../2-loops/README.md)