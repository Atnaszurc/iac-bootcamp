# TF-302: Pre/Post Conditions & Check Blocks

**Course**: TF-300 Series (Testing, Validation & Policy)  
**Level**: 300 (Advanced)  
**Duration**: 1.5 hours  
**Prerequisites**: TF-301 (Input Validation & Advanced Functions)  
**Platform**: Libvirt (local VMs)

---

## 🎯 Course Overview

Welcome to **TF-302: Pre/Post Conditions & Check Blocks**! This course teaches you how to implement **runtime validation** using preconditions, postconditions, and check blocks to ensure your infrastructure is correct throughout its lifecycle.

Learn to validate **before** resource operations (preconditions), **after** resource operations (postconditions), and at the **end of plan/apply** (check blocks) for comprehensive infrastructure validation.

---

## 📚 What You'll Learn

### Core Competencies

After completing TF-302, you will be able to:

- ✅ **Implement Preconditions**: Validate requirements before resource operations
- ✅ **Use Postconditions**: Verify resource state after creation/modification
- ✅ **Create Check Blocks**: Implement final validation with assertions
- ✅ **Choose Validation Types**: Know when to use each validation approach
- ✅ **Validate Cross-Resource**: Check relationships between resources
- ✅ **Provide Clear Errors**: Write helpful error messages for failures
- ✅ **Build Self-Validating Infrastructure**: Create robust, error-resistant code
- ✅ **Write-Only Attributes**: Use `_wo` attributes to pass secrets that are never stored in state (1.11+)

---

## 🗂️ Course Structure

This course has five sections, each in its own subdirectory:

### 1. Pre/Postconditions (`1-pre-postconditions/`)

Learn to use lifecycle conditions for resource-level validation.

**Topics Covered**:
- Precondition syntax and use cases
- Postcondition verification patterns
- Using `self` to reference resource attributes
- Environment-specific validation
- Cross-resource validation

**Hands-on**: a libvirt VM guarded by conditions on the network (no overlap with reserved ranges), the pool (free space), the disk (not smaller than its image), the host (enough memory) and the result (running, with an IP in the right network). Tests show how to mock each one.

**See**: [1-pre-postconditions/README.md](1-pre-postconditions/README.md)

---

### 2. Check Blocks (`2-check-blocks/`)

Master check blocks for final infrastructure validation.

**Topics Covered**:
- Check block syntax (Terraform 1.5+)
- Multiple assertions per check
- Data source integration
- Multi-resource validation
- Grouping related checks

**Hands-on**: an nginx VM with a health check (a scoped `http` data source that expects HTTP 200 and the VM's own name in the page) and a host memory check; drift shows up as a check warning, not an error.

**See**: [2-check-blocks/README.md](2-check-blocks/README.md)

---

### 3. Lifecycle Meta-Arguments (`3-lifecycle-arguments/`)

Master all lifecycle meta-arguments for fine-grained resource control.

**Topics Covered**:
- `create_before_destroy` for zero-downtime updates
- `prevent_destroy` for critical resources
- `ignore_changes` for external modifications
- `replace_triggered_by` for coordinated replacements
- Combining lifecycle arguments effectively

**See**: [3-lifecycle-arguments/README.md](3-lifecycle-arguments/README.md)

---

### 4. Write-Only Attributes (`4-write-only-attributes/`)

Learn to use write-only attributes for secure secret handling (Terraform 1.11+).

**Topics Covered**:
- Write-only attribute syntax (`_wo` suffix)
- Passing secrets without state storage
- Security benefits and use cases
- Migration from regular attributes
- Best practices for secret management

**Hands-on**: a self-signed certificate from the `tls` provider, whose private key goes in through `private_key_pem_wo` and never appears in state; rotation with `private_key_pem_wo_version`.

**See**: [4-write-only-attributes/README.md](4-write-only-attributes/README.md)

---

### 5. Enhanced Deprecation Detection (`5-deprecation-warnings/`) [NEW — Terraform 1.15]

Understand how Terraform 1.15 improves deprecation detection and reporting.

**Topics Covered**:
- Improved detection of deprecated attributes and blocks
- Provider deprecation messages in warnings
- Understanding deprecation warnings
- Migration strategies for deprecated features
- Best practices for handling deprecations

**Hands-on**: real deprecations in the `random` and `null` providers: read the warnings, migrate without changing infrastructure, and fail CI on deprecations with `plan -json`.

**See**: [5-deprecation-warnings/README.md](5-deprecation-warnings/README.md)


---

## 🎓 Learning Objectives

### By the End of This Course

You will be able to:

1. **Implement Preconditions**
   - Validate before resource creation
   - Check dependencies between resources
   - Enforce environment-specific rules
   - Prevent invalid configurations early

2. **Use Postconditions**
   - Verify resource state after creation
   - Check computed attributes
   - Validate security settings
   - Ensure provider defaults are correct

3. **Create Check Blocks**
   - Validate multiple resources together
   - Implement compliance checks
   - Group related validations
   - Provide final verification

4. **Choose Appropriately**
   - Understand when to use each type
   - Layer validations effectively
   - Optimize validation performance
   - Provide helpful error messages

---

## 💡 Key Concepts

### Preconditions (Terraform 1.2+)

Preconditions are checked **before** Terraform attempts to create, update, or destroy a resource.

```hcl
resource "libvirt_domain" "vm" {
  name   = var.vm_name
  memory = var.vm_memory
  vcpu   = var.vm_vcpu
  
  lifecycle {
    precondition {
      condition     = var.environment == "prod" ? var.vm_memory >= 2048 : true
      error_message = "Production VMs must have at least 2 GB of memory."
    }
    
    precondition {
      condition     = var.environment == "prod" ? var.vm_vcpu >= 2 : true
      error_message = "Production VMs must have at least 2 vCPUs."
    }
  }
  
  # ... rest of configuration
}
```

**When to Use**:
- ✅ Validate input variables before resource creation
- ✅ Check dependencies between resources
- ✅ Enforce environment-specific requirements
- ✅ Prevent invalid configurations early

**Benefits**:
- Catches errors before any changes are made
- Provides immediate feedback
- Prevents wasted time on invalid configurations
- Clear error messages guide users

---

### Postconditions (Terraform 1.2+)

Postconditions are checked **after** Terraform has successfully created or updated a resource.

```hcl
resource "libvirt_domain" "vm" {
  name        = var.vm_name
  memory      = var.vm_memory
  memory_unit = "MiB"
  vcpu        = var.vm_vcpu
  type        = "kvm"
  os          = { type = "hvm", type_arch = "x86_64", type_machine = "q35" }

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_volume.os.pool
            volume = libvirt_volume.os.name
          }
        }
        target = { dev = "vda", bus = "virtio" }
      }
    ]
  }

  lifecycle {
    postcondition {
      condition     = self.memory >= 1024
      error_message = "VM memory must be at least 1 GB (1024 MiB). Actual: ${self.memory} MiB"
    }
    
    postcondition {
      condition     = self.vcpu >= 1
      error_message = "VM must have at least 1 vCPU. Actual: ${self.vcpu}"
    }
  }
}
```

**When to Use**:
- ✅ Verify resource attributes after creation
- ✅ Ensure provider defaults meet requirements
- ✅ Validate computed values
- ✅ Check security settings are applied

**Benefits**:
- Verifies actual resource state
- Catches provider-specific issues
- Validates computed attributes
- Ensures configuration was applied correctly

---

### Check Blocks (Terraform 1.5+)

Check blocks run at the end of plan and apply stages, providing final verification.

```hcl
check "vm_configuration" {
  assert {
    condition     = libvirt_domain.web.memory >= 2048
    error_message = "Web server VM must have at least 2 GB memory."
  }
  
  assert {
    condition     = libvirt_domain.web.vcpu >= 2
    error_message = "Web server VM must have at least 2 vCPUs."
  }
  
  assert {
    condition     = libvirt_domain.db.memory >= 4096
    error_message = "Database VM must have at least 4 GB memory."
  }
}
```

**When to Use**:
- ✅ Validate multiple resources together
- ✅ Check complex cross-resource relationships
- ✅ Verify final infrastructure state
- ✅ Implement compliance checks
- ✅ Group related validations

**Benefits**:
- Validates entire infrastructure state
- Groups related checks logically
- Provides final verification
- Doesn't block apply (warnings only)

---

## 📊 Comparison: When to Use Each

| Validation Type | Timing | Scope | Blocks Apply? | Best For |
|----------------|--------|-------|---------------|----------|
| **Variable Validation** | Before plan | Single variable | Yes | Input format/value checks |
| **Preconditions** | Before resource op | Single resource | Yes | Dependency checks, env rules |
| **Postconditions** | After resource op | Single resource | Yes | Verify created state |
| **Check Blocks** | End of plan/apply | Multiple resources | No (warnings) | Final validation, compliance |

### Decision Tree

```
Need to validate?
├─ Input variable format/value?
│  └─ Use: Variable validation (TF-301)
│
├─ Before creating resource?
│  ├─ Single resource requirement?
│  │  └─ Use: Precondition
│  └─ Multiple resources?
│     └─ Use: Check block
│
└─ After creating resource?
   ├─ Verify single resource state?
   │  └─ Use: Postcondition
   └─ Verify multiple resources?
      └─ Use: Check block
```

---

## 🔧 Practical Examples

### Example 1: Environment-Specific Preconditions

```hcl
variable "environment" {
  type = string
}

variable "vm_memory" {
  type = number
}

resource "libvirt_domain" "app" {
  name   = "app-server"
  memory = var.vm_memory
  vcpu   = 2
  
  lifecycle {
    # Production requires more memory
    precondition {
      condition = (
        var.environment == "prod" ? var.vm_memory >= 4096 :
        var.environment == "staging" ? var.vm_memory >= 2048 :
        var.vm_memory >= 1024
      )
      error_message = <<-EOT
        Memory requirements by environment:
        - Production: >= 4 GB (4096 MB)
        - Staging: >= 2 GB (2048 MB)
        - Dev: >= 1 GB (1024 MB)
        Current: ${var.vm_memory} MB in ${var.environment}
      EOT
    }
  }
  
  # ... rest of configuration
}
```

---

### Example 2: Postcondition with `self`

```hcl
resource "libvirt_volume" "os" {
  name     = "os-disk.qcow2"
  pool     = libvirt_pool.default.name
  capacity = var.disk_size * 1024 * 1024 * 1024 # Convert GB to bytes
  target   = { format = { type = "qcow2" } }

  lifecycle {
    postcondition {
      condition     = self.capacity >= 10737418240 # 10 GB in bytes
      error_message = "OS disk must be at least 10 GB. Actual: ${self.capacity / 1024 / 1024 / 1024} GB"
    }
  }
}
```

---

### Example 3: Check Block with Multiple Assertions

```hcl
check "infrastructure_compliance" {
  # Check web server configuration
  assert {
    condition     = libvirt_domain.web.memory >= 2048
    error_message = "Web server requires at least 2 GB memory."
  }
  
  assert {
    condition     = libvirt_domain.web.vcpu >= 2
    error_message = "Web server requires at least 2 vCPUs."
  }
  
  # Check database server configuration
  assert {
    condition     = libvirt_domain.db.memory >= 4096
    error_message = "Database server requires at least 4 GB memory."
  }
  
  assert {
    condition     = libvirt_domain.db.vcpu >= 4
    error_message = "Database server requires at least 4 vCPUs."
  }
  
  # Check network configuration
  assert {
    condition     = length(libvirt_network.app.addresses) > 0
    error_message = "Network must have at least one address range."
  }
}
```

---

### Example 4: Cross-Resource Validation

```hcl
resource "libvirt_network" "app" {
  name    = "app-network"
  forward = { mode = "nat" }
  ips = [{
    address = "10.0.1.1"
    prefix  = 24
    dhcp    = { ranges = [{ start = "10.0.1.100", end = "10.0.1.200" }] }
  }]
}

resource "libvirt_domain" "web" {
  name        = "web-server"
  memory      = 2048
  memory_unit = "MiB"
  vcpu        = 2
  type        = "kvm"
  os          = { type = "hvm", type_arch = "x86_64", type_machine = "q35" }

  devices = {
    interfaces = [
      {
        model  = { type = "virtio" }
        source = { network = { network = libvirt_network.app.name } }
      }
    ]
  }

  lifecycle {
    # The web server needs outbound access, so its network must forward traffic
    precondition {
      condition     = libvirt_network.app.forward != null
      error_message = "The app network is isolated (no forward). The web server needs outbound access."
    }

    # Verify VM is connected to a network. This catches a real trap: Terraform
    # silently ignores misspelled keys inside nested attributes, so a typo
    # like "interface" instead of "interfaces" gives a VM with no NIC.
    postcondition {
      condition     = length(coalesce(self.devices.interfaces, [])) > 0
      error_message = "VM must have at least one network interface."
    }
  }
}
```

---

## 🧪 Hands-On Labs

### Lab 1: Preconditions for Environment Rules (15 minutes)

**Objective**: Implement preconditions that enforce environment-specific requirements.

**Tasks**:
1. Create environment variable (dev/staging/prod)
2. Create VM resource with memory and vCPU variables
3. Add preconditions:
   - Production: ≥4 GB memory, ≥2 vCPUs
   - Staging: ≥2 GB memory, ≥2 vCPUs
   - Dev: ≥1 GB memory, ≥1 vCPU
4. Test with different environments
5. Observe error messages for violations

**Expected Outcome**: Understanding of precondition syntax and environment-based validation.

---

### Lab 2: Postconditions for State Verification (20 minutes)

**Objective**: Use postconditions to verify resource state after creation.

**Tasks**:
1. Create volume resource with size variable
2. Add postcondition to verify minimum size
3. Create VM resource
4. Add postconditions to verify:
   - Memory is at least 1 GB
   - vCPU count is at least 1
   - Network interface exists
5. Apply configuration
6. Verify postconditions pass

**Expected Outcome**: Understanding of postcondition usage and `self` reference.

---

### Lab 3: Check Blocks for Final Validation (25 minutes)

**Objective**: Implement check blocks for comprehensive infrastructure validation.

**Tasks**:
1. Create multi-tier infrastructure (web + db VMs)
2. Create check block for web server:
   - Memory ≥2 GB
   - vCPU ≥2
3. Create check block for database:
   - Memory ≥4 GB
   - vCPU ≥4
4. Create check block for network:
   - At least one address range
   - Mode is "nat"
5. Apply and observe check results
6. Intentionally violate a check to see warnings

**Expected Outcome**: Mastery of check blocks and multi-resource validation.

---

## ✅ Checkpoint Quiz

Test your understanding with these questions:

### Question 1: Precondition Timing
**Q**: When are preconditions evaluated during the Terraform workflow?

<details>
<summary>Click to see answer</summary>

**A**: Preconditions are evaluated **before** Terraform attempts to create, update, or destroy a resource. They run during the plan phase, before any actual infrastructure changes are made.

**Why this matters**: This allows you to catch configuration errors early, before wasting time on invalid operations. If a precondition fails, Terraform stops and shows the error message without making any changes.
</details>

---

### Question 2: The `self` Object
**Q**: What is the `self` object in postconditions, and what can you access with it?

<details>
<summary>Click to see answer</summary>

**A**: The `self` object represents the resource instance after it has been created or updated. You can access any attribute of the resource using `self.attribute_name`.

**Example**:
```hcl
postcondition {
  condition     = self.memory >= 2048
  error_message = "Memory: ${self.memory} MB"
}
```

**Limitation**: `self` is only available in postconditions, not preconditions (because the resource doesn't exist yet).
</details>

---

### Question 3: Check Blocks vs Conditions
**Q**: What's the key difference between check blocks and preconditions/postconditions in terms of behavior?

<details>
<summary>Click to see answer</summary>

**A**: 
- **Preconditions/Postconditions**: **Block** the operation if they fail. Terraform stops and shows an error.
- **Check Blocks**: **Warn** if they fail but don't block the operation. Terraform shows warnings but continues.

**Use Case**: Use check blocks for "nice to have" validations or compliance checks that shouldn't prevent deployment, but should be monitored.
</details>

---

### Question 4: Multiple Assertions
**Q**: Can a check block have multiple `assert` blocks? How are they evaluated?

<details>
<summary>Click to see answer</summary>

**A**: Yes, a check block can have multiple `assert` blocks. All assertions are evaluated independently, and Terraform reports all failures (not just the first one).

**Example**:
```hcl
check "compliance" {
  assert {
    condition     = libvirt_domain.web.memory >= 2048
    error_message = "Web server memory check failed."
  }
  
  assert {
    condition     = libvirt_domain.db.memory >= 4096
    error_message = "Database memory check failed."
  }
}
```

**Benefit**: You see all validation failures at once, not just the first one.
</details>

---

### Question 5: Validation Layering
**Q**: In what order should you layer validations for comprehensive infrastructure validation?

<details>
<summary>Click to see answer</summary>

**A**: The recommended validation layers, in order:

1. **Variable Validation** (TF-301): Validate input format and basic rules
2. **Preconditions**: Check environment rules and dependencies before creation
3. **Resource Creation**: Terraform applies the configuration
4. **Postconditions**: Verify resource state after creation
5. **Check Blocks**: Final compliance and cross-resource validation

**Why this order**: Each layer catches different types of issues at the appropriate time, providing comprehensive validation without redundancy.
</details>

---

### Question 6: Error Messages
**Q**: What makes a good error message in conditions and check blocks?

<details>
<summary>Click to see answer</summary>

**A**: A good error message should:

1. **Explain what's wrong**: "Memory is below minimum"
2. **Show actual vs expected**: "Expected: ≥2048 MB, Actual: ${self.memory} MB"
3. **Provide context**: "Production VMs require at least 2 GB"
4. **Be actionable**: Tell the user how to fix it

**Bad Example**:
```hcl
error_message = "Invalid configuration"
```

**Good Example**:
```hcl
error_message = <<-EOT
  Production VMs require at least 2 GB memory.
  Expected: >= 2048 MB
  Actual: ${var.vm_memory} MB
  Fix: Increase vm_memory to at least 2048
EOT
```
</details>

---

## 📚 Best Practices

### 1. Use Appropriate Validation Type

```hcl
# ✅ GOOD: Variable validation for format
variable "vm_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.vm_name))
    error_message = "VM name must be lowercase alphanumeric with hyphens."
  }
}

# ✅ GOOD: Precondition for environment rules
resource "libvirt_domain" "vm" {
  lifecycle {
    precondition {
      condition     = var.environment == "prod" ? var.vm_memory >= 4096 : true
      error_message = "Production requires >= 4 GB memory."
    }
  }
}

# ✅ GOOD: Postcondition for created state
resource "libvirt_domain" "vm" {
  lifecycle {
    postcondition {
      condition     = self.memory >= 1024
      error_message = "VM must have >= 1 GB memory."
    }
  }
}

# ✅ GOOD: Check block for final compliance
check "compliance" {
  assert {
    condition     = libvirt_domain.vm.memory >= 2048
    error_message = "Compliance requires >= 2 GB memory."
  }
}
```

---

### 2. Provide Context in Error Messages

```hcl
# ❌ BAD: Vague message
lifecycle {
  precondition {
    condition     = var.vm_memory >= 2048
    error_message = "Invalid memory."
  }
}

# ✅ GOOD: Detailed, actionable message
lifecycle {
  precondition {
    condition     = var.vm_memory >= 2048
    error_message = <<-EOT
      VM memory must be at least 2 GB (2048 MB).
      Current value: ${var.vm_memory} MB
      Environment: ${var.environment}
      Fix: Set vm_memory to at least 2048
    EOT
  }
}
```

---

### 3. Group Related Checks

```hcl
# ✅ GOOD: Group related validations
check "web_server_compliance" {
  assert {
    condition     = libvirt_domain.web.memory >= 2048
    error_message = "Web server memory requirement."
  }
  
  assert {
    condition     = libvirt_domain.web.vcpu >= 2
    error_message = "Web server vCPU requirement."
  }
}

check "database_compliance" {
  assert {
    condition     = libvirt_domain.db.memory >= 4096
    error_message = "Database memory requirement."
  }
  
  assert {
    condition     = libvirt_domain.db.vcpu >= 4
    error_message = "Database vCPU requirement."
  }
}
```

---

### 4. Use Data Sources in Check Blocks

A data source declared *inside* a check block is scoped to it: if it fails, you get a warning instead of a failed plan.

```hcl
check "web_server_has_address" {
  # Ask libvirt which address DHCP handed out
  data "libvirt_domain_interface_addresses" "web" {
    domain = libvirt_domain.web.name
    source = "lease"
  }

  assert {
    condition     = length(data.libvirt_domain_interface_addresses.web.interfaces) > 0
    error_message = "web-server has no DHCP lease. Is it running?"
  }

  assert {
    condition = alltrue([
      for i in data.libvirt_domain_interface_addresses.web.interfaces : alltrue([
        for a in i.addrs : a.type != "ipv4" || cidrhost("10.0.1.0/24", 0) == cidrhost("${a.addr}/24", 0)
      ])
    ])
    error_message = "web-server has an IPv4 address outside the app network (10.0.1.0/24)."
  }
}
```

---

### 5. Layer Validations Appropriately

```hcl
# Layer 1: Variable validation (format)
variable "vm_memory" {
  type = number
  validation {
    condition     = var.vm_memory >= 512
    error_message = "Memory must be at least 512 MB."
  }
}

# Layer 2: Precondition (environment rules)
resource "libvirt_domain" "vm" {
  memory = var.vm_memory
  
  lifecycle {
    precondition {
      condition     = var.environment == "prod" ? var.vm_memory >= 4096 : true
      error_message = "Production requires >= 4 GB."
    }
    
    # Layer 3: Postcondition (verify state)
    postcondition {
      condition     = self.memory == var.vm_memory
      error_message = "Memory mismatch: expected ${var.vm_memory}, got ${self.memory}"
    }
  }
}

# Layer 4: Check block (final compliance)
check "vm_compliance" {
  assert {
    condition     = libvirt_domain.vm.memory >= 1024
    error_message = "Final check: VM must have >= 1 GB."
  }
}
```

---

## 📦 Supplemental Content

Extend your TF-302 knowledge with these additional topics:

| Section | Topic | Description |
|---------|-------|-------------|
| [3-lifecycle-arguments/](3-lifecycle-arguments/README.md) | `lifecycle` Meta-Arguments (Complete Unit) | All lifecycle arguments: `create_before_destroy`, `prevent_destroy`, `ignore_changes`, `replace_triggered_by` |
| [4-write-only-attributes/](4-write-only-attributes/README.md) | Write-Only Attributes (1.11+) | Provider-defined `_wo` attributes that accept secrets but are never stored in state; `_wo_version` pattern for rotation; works with ephemeral values |

---

## 🔗 Related Topics

### Prerequisites
- **TF-301**: Input Validation & Advanced Functions

### Next Steps
- **TF-303**: Terraform Test Framework
- **TF-304**: Policy as Code

### Related Concepts
- Lifecycle meta-argument (complete unit in Supplemental)
- Resource dependencies
- Data sources
- Conditional expressions

---

## 📖 Additional Resources

### Official Documentation
- [Lifecycle Meta-Argument](https://www.terraform.io/language/meta-arguments/lifecycle)
- [Custom Conditions](https://www.terraform.io/language/expressions/custom-conditions)
- [Check Blocks](https://www.terraform.io/language/checks)
- [Preconditions and Postconditions](https://www.terraform.io/language/expressions/custom-conditions#preconditions-and-postconditions)

### Community Resources
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Validation Patterns](https://github.com/hashicorp/terraform/issues)

---

## 🎯 Success Criteria

You've successfully completed TF-302 when you can:

- [ ] Implement preconditions for resources
- [ ] Use postconditions to verify state
- [ ] Create check blocks with assertions
- [ ] Choose the right validation type
- [ ] Write clear error messages
- [ ] Validate cross-resource relationships
- [ ] Layer validations appropriately
- [ ] Group related checks logically

---

## 🔄 What's Next?

After completing TF-302:

1. **Practice**: Complete all three hands-on labs
2. **Apply**: Add conditions to your existing modules
3. **Continue**: Move on to TF-303 (Terraform Test Framework)
4. **Experiment**: Try different validation patterns

---

**Course Navigation**:
- [← Back to TF-301](../TF-301-validation/)
- [→ Section 1: Pre/Postconditions](1-pre-postconditions/)
- [→ Section 2: Check Blocks](2-check-blocks/)
- [→ Next Course: TF-303](../TF-303-test-framework/)

**Need Help?**
- Review [TF-301](../TF-301-validation/) for variable validation
- Check [Course Catalog](../../../docs/course-catalog.md)
- See [Learning Progression](../../../docs/learning-progression.md)

---

*Last Updated: 2026-02-26*  
*Course Version: 3.0*  
*Terraform Version: 1.14+*