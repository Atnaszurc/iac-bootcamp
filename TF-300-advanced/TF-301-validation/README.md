# TF-301: Input Validation & Advanced Functions

**Course**: TF-300 Series (Testing, Validation & Policy)  
**Level**: 300 (Advanced)  
**Duration**: 1.5 hours  
**Prerequisites**: TF-200 series (Terraform Modules & Patterns)  
**Platform**: Libvirt (local VMs)

---

## 🎯 Course Overview

Welcome to **TF-301: Input Validation & Advanced Functions**! This course teaches you how to implement **robust input validation** and master **advanced Terraform functions** to create self-validating, error-resistant infrastructure code.

Learn to catch configuration errors **before deployment**, provide helpful error messages, and use advanced functions like `try()`, `can()`, and complex data transformations.

---

## 📚 What You'll Learn

### Core Competencies

After completing TF-301, you will be able to:

- ✅ **Implement Variable Validation**: Create comprehensive validation rules for inputs
- ✅ **Use Advanced Functions**: Master `try()`, `can()`, and error handling patterns
- ✅ **Validate Complex Data**: Check nested objects, lists, and maps
- ✅ **Provide Clear Errors**: Write helpful, actionable error messages
- ✅ **Cross-Variable Validation**: Validate relationships between variables
- ✅ **Type Checking**: Ensure data types are correct before use
- ✅ **Regex Patterns**: Use regular expressions for string validation
- ✅ **Ephemeral Values**: Use `ephemeral = true` to prevent secrets from ever touching state (1.10+)

---

## 🗂️ Course Structure

This course has two main sections with subdirectories:

### 1. Variable Conditions (`1-variable-conditions/`)

Learn to implement robust input validation using Terraform's validation blocks.

**Topics Covered**:
- Basic validation syntax (Terraform 1.14+)
- Single and multiple validation blocks
- Regex patterns for string validation
- Cross-variable validation
- Complex validation logic
- Error message best practices

**See**: [1-variable-conditions/README.md](1-variable-conditions/README.md)

---

### 2. Advanced Functions (`2-advanced-functions/`)

Master advanced Terraform functions for error handling and data transformation.

**Topics Covered**:
- `try()` function for error handling
- `can()` function for capability testing
- Type conversion functions
- Function chaining patterns
- Conditional logic with functions
- Error recovery strategies

**See**: [2-advanced-functions/README.md](2-advanced-functions/README.md)

---

## 🎓 Learning Objectives

### By the End of This Course

You will be able to:

1. **Write Validation Rules**
   - Implement single and multiple validation blocks
   - Use regex patterns for string validation
   - Validate numbers, lists, and maps
   - Create cross-variable validation logic

2. **Use Advanced Functions**
   - Handle errors gracefully with `try()`
   - Test capabilities with `can()`
   - Convert between data types safely
   - Chain functions for complex operations

3. **Provide User Feedback**
   - Write clear, actionable error messages
   - Explain what's wrong and how to fix it
   - Guide users to correct configurations

4. **Build Robust Modules**
   - Validate all inputs comprehensively
   - Prevent common configuration errors
   - Create self-documenting code
   - Reduce runtime failures

---

## 💡 Key Concepts

### Variable Validation (Terraform 1.14+)

Terraform allows you to validate variable inputs before they're used:

```hcl
variable "vm_name" {
  type        = string
  description = "Name for the virtual machine"
  
  validation {
    condition     = can(regex("^[a-z0-9-]{3,15}$", var.vm_name))
    error_message = "VM name must be 3-15 characters, lowercase letters, numbers, and hyphens only."
  }
}
```

**Benefits**:
- ✅ Catch errors during `terraform plan`
- ✅ Provide immediate feedback
- ✅ Prevent invalid configurations
- ✅ Enforce organizational standards

---

### Multiple Validation Blocks

You can have multiple validation blocks per variable:

```hcl
variable "vm_memory" {
  type        = number
  description = "Memory in MB"
  
  validation {
    condition     = var.vm_memory >= 512
    error_message = "VM memory must be at least 512 MB."
  }
  
  validation {
    condition     = var.vm_memory <= 16384
    error_message = "VM memory must be at most 16 GB (16384 MB)."
  }
  
  validation {
    condition     = var.vm_memory % 512 == 0
    error_message = "VM memory must be a multiple of 512 MB."
  }
}
```

**Why Multiple Blocks?**
- Each block tests one specific rule
- Provides specific error messages
- Easier to understand and maintain
- Better user experience

---

### Cross-Variable Validation

Reference other variables in validation conditions:

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vm_count" {
  type        = number
  description = "Number of VMs to create"
  
  validation {
    condition     = var.environment == "prod" ? var.vm_count >= 2 : true
    error_message = "Production environment must have at least 2 VMs for high availability."
  }
}
```

**Use Cases**:
- Environment-specific rules
- Dependent configuration validation
- Business logic enforcement
- Compliance requirements

---

### The `can()` Function

Test if an expression succeeds without causing an error:

```hcl
variable "ip_address" {
  type = string
  
  validation {
    # Try to parse as CIDR, return true if successful
    condition     = can(cidrhost(var.ip_address, 0))
    error_message = "Must be a valid IP address or CIDR block."
  }
}
```

**Common Uses**:
- Test regex patterns: `can(regex("pattern", var.value))`
- Test type conversions: `can(tonumber(var.value))`
- Test function calls: `can(cidrhost(var.cidr, 0))`
- Test lookups: `can(lookup(var.map, "key"))`

---

### The `try()` Function

Attempt expressions in order, return first successful result:

```hcl
locals {
  # Try to get value from map, fallback to default
  vm_size = try(
    var.vm_sizes[var.environment],  # Try environment-specific size
    var.vm_sizes["default"],         # Try default size
    "small"                          # Final fallback
  )
}
```

**Use Cases**:
- Provide fallback values
- Handle optional attributes
- Graceful error recovery
- Flexible configuration

---

## 🔧 Practical Examples

### Example 1: VM Name Validation

```hcl
variable "vm_name" {
  type        = string
  description = "Name for the virtual machine"
  
  validation {
    condition     = length(var.vm_name) >= 3 && length(var.vm_name) <= 15
    error_message = "VM name must be between 3 and 15 characters."
  }
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.vm_name))
    error_message = "VM name must start with a letter, end with letter/number, contain only lowercase letters, numbers, and hyphens."
  }
}
```

---

### Example 2: Network CIDR Validation

```hcl
variable "network_cidr" {
  type        = string
  description = "CIDR block for the network"
  
  validation {
    condition     = can(cidrhost(var.network_cidr, 0))
    error_message = "Must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
  
  validation {
    condition     = tonumber(split("/", var.network_cidr)[1]) >= 16
    error_message = "Network must be at least /16 (65,536 addresses)."
  }
}
```

---

### Example 3: Complex Object Validation

```hcl
variable "vm_config" {
  type = object({
    name   = string
    memory = number
    vcpu   = number
    disk   = number
  })
  
  validation {
    condition     = can(regex("^[a-z0-9-]{3,15}$", var.vm_config.name))
    error_message = "VM name must be 3-15 characters, lowercase alphanumeric and hyphens."
  }
  
  validation {
    condition     = var.vm_config.memory >= 512 && var.vm_config.memory <= 16384
    error_message = "Memory must be between 512 MB and 16 GB."
  }
  
  validation {
    condition     = var.vm_config.vcpu >= 1 && var.vm_config.vcpu <= 8
    error_message = "vCPU count must be between 1 and 8."
  }
  
  validation {
    condition     = var.vm_config.disk >= 10 && var.vm_config.disk <= 500
    error_message = "Disk size must be between 10 GB and 500 GB."
  }
}
```

---

## 🧪 Hands-On Labs

### Lab 1: Basic Variable Validation (15 minutes)

**Objective**: Implement validation for VM configuration variables.

**Tasks**:
1. Create variables for VM name, memory, and vCPU count
2. Add validation rules:
   - VM name: 3-15 chars, lowercase alphanumeric
   - Memory: 512-16384 MB, multiples of 512
   - vCPU: 1-8 cores
3. Test with valid and invalid values
4. Observe error messages

**Expected Outcome**: Understanding of basic validation syntax and error handling.

---

### Lab 2: Cross-Variable Validation (20 minutes)

**Objective**: Implement validation that depends on multiple variables.

**Tasks**:
1. Create environment variable (dev/staging/prod)
2. Create VM count variable
3. Add validation:
   - Production must have ≥2 VMs
   - Staging must have ≥1 VM
   - Dev can have any count
4. Create disk size variable
5. Add validation:
   - Production disks must be ≥50 GB
   - Other environments ≥10 GB
6. Test different environment combinations

**Expected Outcome**: Understanding of cross-variable validation patterns.

---

### Lab 3: Advanced Functions & Error Handling (25 minutes)

**Objective**: Use `try()` and `can()` for robust configuration.

**Tasks**:
1. Create a map of VM sizes by environment
2. Use `try()` to get size with fallbacks
3. Create CIDR validation using `can(cidrhost())`
4. Implement type checking with `can(tonumber())`
5. Create a complex naming function with `try()`
6. Test error scenarios and fallbacks

**Expected Outcome**: Mastery of advanced function usage and error handling.

---

## ✅ Checkpoint Quiz

Test your understanding with these questions:

### Question 1: Validation Basics
**Q**: What happens if a validation condition fails during `terraform plan`?

<details>
<summary>Click to see answer</summary>

**A**: Terraform stops the plan phase and displays the `error_message` from the failed validation block. The plan does not proceed, preventing invalid configurations from being applied.

**Why this matters**: Validation catches errors early, before any infrastructure changes are attempted.
</details>

---

### Question 2: Multiple Validations
**Q**: Can a variable have multiple validation blocks? If yes, how are they evaluated?

<details>
<summary>Click to see answer</summary>

**A**: Yes, a variable can have multiple validation blocks. All validation blocks must pass for the variable to be considered valid. They are evaluated in order, and the first failure stops evaluation and shows that error message.

**Best Practice**: Use multiple blocks to test different aspects of the input, providing specific error messages for each rule.
</details>

---

### Question 3: The `can()` Function
**Q**: What does `can(regex("^[a-z]+$", var.name))` return if the regex fails to match?

<details>
<summary>Click to see answer</summary>

**A**: It returns `false`. The `can()` function catches errors and returns `false` if the expression fails, or `true` if it succeeds. This prevents the regex failure from causing a Terraform error.

**Usage**: Perfect for validation conditions where you want to test if something is valid without causing an error.
</details>

---

### Question 4: Cross-Variable Validation
**Q**: In cross-variable validation, can you reference variables that are defined later in the file?

<details>
<summary>Click to see answer</summary>

**A**: Yes! Terraform evaluates all variables before checking validations, so you can reference any variable regardless of definition order. However, you can only reference other variables, not resources or data sources.

**Limitation**: You cannot reference `local` values, resources, or data sources in variable validation blocks.
</details>

---

### Question 5: The `try()` Function
**Q**: What is the difference between `try()` and `can()`?

<details>
<summary>Click to see answer</summary>

**A**: 
- **`try()`**: Attempts expressions in order and returns the first successful result. Used for providing fallback values.
- **`can()`**: Tests if an expression succeeds and returns `true` or `false`. Used for testing/validation.

**Example**:
```hcl
# try() - returns a value
value = try(var.optional_value, "default")

# can() - returns true/false
is_valid = can(regex("^[a-z]+$", var.name))
```
</details>

---

### Question 6: Error Messages
**Q**: What makes a good validation error message?

<details>
<summary>Click to see answer</summary>

**A**: A good error message should:
1. **Explain what's wrong**: "VM name contains invalid characters"
2. **Explain the rule**: "VM names must contain only lowercase letters, numbers, and hyphens"
3. **Provide an example**: "Example: web-server-01"
4. **Be actionable**: Tell the user how to fix it

**Bad**: "Invalid input"  
**Good**: "VM name must be 3-15 characters, lowercase letters, numbers, and hyphens only. Example: web-server-01"
</details>

---

## 📚 Best Practices

### 1. Validate Early and Often
```hcl
# ✅ GOOD: Validate at variable level
variable "vm_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.vm_name))
    error_message = "Invalid VM name format."
  }
}

# ❌ BAD: No validation, errors happen at apply time
variable "vm_name" {
  type = string
}
```

---

### 2. Use Multiple Validation Blocks
```hcl
# ✅ GOOD: Separate validations with specific messages
variable "memory" {
  type = number
  
  validation {
    condition     = var.memory >= 512
    error_message = "Memory must be at least 512 MB."
  }
  
  validation {
    condition     = var.memory % 512 == 0
    error_message = "Memory must be a multiple of 512 MB."
  }
}

# ❌ BAD: Combined validation with generic message
variable "memory" {
  type = number
  
  validation {
    condition     = var.memory >= 512 && var.memory % 512 == 0
    error_message = "Invalid memory configuration."
  }
}
```

---

### 3. Provide Helpful Error Messages
```hcl
# ✅ GOOD: Specific, actionable message
validation {
  condition     = can(regex("^[a-z0-9-]{3,15}$", var.vm_name))
  error_message = "VM name must be 3-15 characters, lowercase letters, numbers, and hyphens only. Example: web-server-01"
}

# ❌ BAD: Vague message
validation {
  condition     = can(regex("^[a-z0-9-]{3,15}$", var.vm_name))
  error_message = "Invalid name."
}
```

---

### 4. Use `can()` for Safe Testing
```hcl
# ✅ GOOD: Safe regex testing
validation {
  condition     = can(regex("^[a-z]+$", var.name))
  error_message = "Name must contain only lowercase letters."
}

# ❌ BAD: Regex without can() causes errors
validation {
  condition     = regex("^[a-z]+$", var.name) != null
  error_message = "Name must contain only lowercase letters."
}
```

---

### 5. Use `try()` for Fallbacks
```hcl
# ✅ GOOD: Graceful fallback
locals {
  vm_size = try(
    var.vm_sizes[var.environment],
    var.vm_sizes["default"],
    "small"
  )
}

# ❌ BAD: No fallback, fails if key missing
locals {
  vm_size = var.vm_sizes[var.environment]
}
```

---

## 📦 Supplemental Content

Extend your TF-301 knowledge with these additional topics:

| Section | Topic | Description |
|---------|-------|-------------|
| [3-sensitive-values/](3-sensitive-values/README.md) | `sensitive` Variables & `nonsensitive()` | Suppress secrets in plan/apply output; understand what `sensitive` does and doesn't protect |
| [4-cross-variable-validation/](4-cross-variable-validation/README.md) | Cross-Variable Validation (1.9+) | Validation conditions that reference other variables — enforce environment-specific rules, feature flag consistency, and compliance requirements |
| [5-ephemeral-values/](5-ephemeral-values/README.md) | Ephemeral Values (1.10+) | `ephemeral = true` on variables and outputs — values that are NEVER written to state or plan files; `ephemeralasnull()` function |

---

## 🔗 Related Topics

### Prerequisites
- **TF-200**: Module Design & Composition
- **TF-202**: Advanced Module Patterns

### Next Steps
- **TF-302**: Pre/Post Conditions & Check Blocks
- **TF-303**: Terraform Test Framework
- **TF-304**: Policy as Code

### Related Concepts
- Input variables and types
- Local values and expressions
- Conditional expressions
- Function reference

---

## 📖 Additional Resources

### Official Documentation
- [Variable Validation](https://www.terraform.io/language/values/variables#custom-validation-rules)
- [Functions Reference](https://www.terraform.io/language/functions)
- [try() Function](https://www.terraform.io/language/functions/try)
- [can() Function](https://www.terraform.io/language/functions/can)

### Community Resources
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Input Validation Patterns](https://github.com/hashicorp/terraform/issues)

---

## 🎯 Success Criteria

You've successfully completed TF-301 when you can:

- [ ] Write validation blocks for variables
- [ ] Use regex patterns for string validation
- [ ] Implement cross-variable validation
- [ ] Use `can()` for safe testing
- [ ] Use `try()` for fallback values
- [ ] Write clear, helpful error messages
- [ ] Validate complex data structures
- [ ] Apply validation best practices

---

## 🔄 What's Next?

After completing TF-301:

1. **Practice**: Complete all three hands-on labs
2. **Apply**: Add validation to your existing modules
3. **Continue**: Move on to TF-302 (Pre/Post Conditions & Check Blocks)
4. **Experiment**: Try validation with different data types

---

**Course Navigation**:
- [← Back to TF-300 Series](../)
- [→ Section 1: Variable Conditions](1-variable-conditions/)
- [→ Section 2: Advanced Functions](2-advanced-functions/)
- [→ Next Course: TF-302](../TF-302-conditions-checks/)

**Need Help?**
- Review [TF-200 Series](../../TF-200-modules/) for module basics
- Check [Course Catalog](../../../docs/course-catalog.md)
- See [Learning Progression](../../../docs/learning-progression.md)

---

*Last Updated: 2026-02-26*  
*Course Version: 3.0*  
*Terraform Version: 1.14+*