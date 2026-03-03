# TF-304: Policy as Code (OPA/Rego)

**Course**: TF-300 Advanced Terraform  
**Module**: TF-304  
**Duration**: 1 hour  
**Prerequisites**: TF-303 (Terraform Test Framework)  
**Tools**: Open Policy Agent (OPA), Rego language

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Introduction to Policy as Code](#introduction-to-policy-as-code)
4. [Why Policy as Code?](#why-policy-as-code)
5. [Open Policy Agent (OPA) Overview](#open-policy-agent-opa-overview)
6. [Rego Language Basics](#rego-language-basics)
7. [OPA with Terraform](#opa-with-terraform)
8. [Writing Your First Policy](#writing-your-first-policy)
9. [Policy Structure and Organization](#policy-structure-and-organization)
10. [Common Policy Patterns](#common-policy-patterns)
11. [Testing Policies](#testing-policies)
12. [Policy Enforcement Levels](#policy-enforcement-levels)
13. [Sentinel Overview (Enterprise)](#sentinel-overview-enterprise)
14. [Best Practices](#best-practices)
15. [Hands-On Labs](#hands-on-labs)
16. [Checkpoint Quiz](#checkpoint-quiz)
17. [Additional Resources](#additional-resources)

---

## Course Overview

Policy as Code allows you to define, version, and enforce organizational standards and compliance requirements as code. This course covers Open Policy Agent (OPA) with Rego for policy enforcement in Terraform, with an overview of HashiCorp Sentinel for enterprise users.

### What You'll Build

- OPA policies for Libvirt infrastructure
- Resource naming conventions
- Security policies (network, storage)
- Compliance checks
- Policy test suites

### Why This Matters

- **Compliance**: Enforce regulatory requirements
- **Security**: Prevent misconfigurations
- **Governance**: Maintain organizational standards
- **Automation**: Shift-left security and compliance
- **Consistency**: Ensure uniform infrastructure

---

## Learning Objectives

By the end of this course, you will be able to:

1. ✅ Understand Policy as Code concepts
2. ✅ Write OPA policies in Rego language
3. ✅ Integrate OPA with Terraform workflows
4. ✅ Test policies with OPA test framework
5. ✅ Implement common policy patterns
6. ✅ Understand policy enforcement levels
7. ✅ Compare OPA and Sentinel approaches
8. ✅ Apply best practices for policy development

---

## Introduction to Policy as Code

### What is Policy as Code?

Policy as Code is the practice of defining organizational policies, compliance rules, and security standards as executable code that can be:

- **Versioned**: Track changes in Git
- **Tested**: Automated testing like application code
- **Reviewed**: Code review processes
- **Automated**: Integrated into CI/CD pipelines
- **Enforced**: Automatically applied to infrastructure

### The Policy Enforcement Pyramid

```
        /\
       /  \      Advisory (Warnings)
      /____\     - Inform users
     /      \    - No blocking
    /________\   Soft Mandatory (Can Override)
   /          \  - Require justification
  /____________\ Hard Mandatory (Blocking)
                 - Cannot proceed
```

### Policy vs Validation

| Aspect | Validation (TF-301/302) | Policy (TF-304) |
|--------|-------------------------|-----------------|
| **Scope** | Input correctness | Organizational rules |
| **Location** | Terraform code | External policy engine |
| **Flexibility** | Per-module | Centralized |
| **Enforcement** | Always on | Configurable levels |
| **Audience** | Developers | Compliance/Security teams |

---

## Why Policy as Code?

### Traditional Approach Problems

❌ **Manual Reviews**: Slow, inconsistent, error-prone  
❌ **Documentation**: Outdated, ignored  
❌ **Tribal Knowledge**: Not scalable  
❌ **Post-Deployment**: Expensive to fix  
❌ **Audit Trails**: Hard to track compliance

### Policy as Code Benefits

✅ **Automated Enforcement**: Consistent application  
✅ **Shift-Left**: Catch issues early  
✅ **Version Control**: Track policy changes  
✅ **Testable**: Verify policy correctness  
✅ **Scalable**: Apply across organization  
✅ **Auditable**: Clear compliance trail

### Use Cases

1. **Security**: Prevent insecure configurations
2. **Compliance**: Enforce regulatory requirements (GDPR, HIPAA, SOC2)
3. **Cost Control**: Limit expensive resources
4. **Naming Standards**: Enforce conventions
5. **Tagging**: Ensure proper resource tagging
6. **Network Security**: Validate firewall rules

---

## Open Policy Agent (OPA) Overview

### What is OPA?

**Open Policy Agent** is an open-source, general-purpose policy engine that:

- Uses **Rego** language for policy definition
- Works with **JSON/YAML** data
- Provides **REST API** for policy evaluation
- Supports **multiple integrations** (Kubernetes, Terraform, etc.)
- Offers **built-in testing** framework

### OPA Architecture

```
┌─────────────────┐
│  Terraform Plan │
│   (JSON data)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   OPA Engine    │
│  ┌───────────┐  │
│  │   Rego    │  │
│  │ Policies  │  │
│  └───────────┘  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Policy Decision │
│  (Allow/Deny)   │
└─────────────────┘
```

### Installing OPA

**Linux/macOS**:
```bash
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
chmod +x opa
sudo mv opa /usr/local/bin/
```

**Windows (PowerShell)**:
```powershell
Invoke-WebRequest -Uri https://openpolicyagent.org/downloads/latest/opa_windows_amd64.exe -OutFile opa.exe
Move-Item opa.exe C:\Windows\System32\
```

**Verify Installation**:
```bash
opa version
```

---

## Rego Language Basics

### Rego Fundamentals

Rego is a declarative language designed for policy definition:

- **Declarative**: Describe what should be true
- **Logic-based**: Similar to Prolog/Datalog
- **JSON-native**: Works naturally with JSON data
- **Composable**: Build complex policies from simple rules

### Basic Syntax

```rego
# Package declaration (namespace)
package terraform.libvirt

# Import statements
import future.keywords.if
import future.keywords.contains

# Simple rule
allow if {
    input.resource_type == "libvirt_network"
}

# Rule with conditions
deny[msg] {
    resource := input.resources[_]
    resource.type == "libvirt_domain"
    resource.values.memory < 512
    msg := sprintf("VM %s has insufficient memory: %d MB", [resource.name, resource.values.memory])
}
```

### Rego Data Types

```rego
# Strings
name := "my-network"

# Numbers
memory := 2048

# Booleans
autostart := true

# Arrays
allowed_sizes := [512, 1024, 2048, 4096]

# Objects
vm_config := {
    "name": "test-vm",
    "memory": 2048,
    "vcpu": 2
}

# Sets
unique_names := {"vm1", "vm2", "vm3"}
```

### Rego Operators

```rego
# Comparison
x == y    # Equal
x != y    # Not equal
x < y     # Less than
x <= y    # Less than or equal
x > y     # Greater than
x >= y    # Greater than or equal

# Logical
x; y      # OR
x, y      # AND
not x     # NOT

# Membership
x in array        # Element in array
x in object       # Key in object
```

### Rego Built-in Functions

```rego
# String functions
startswith(string, prefix)
endswith(string, suffix)
contains(string, substring)
sprintf(format, args)

# Array functions
count(array)
sum(array)
max(array)
min(array)

# Set operations
intersection(set1, set2)
union(set1, set2)

# Type checking
is_string(x)
is_number(x)
is_boolean(x)
is_array(x)
is_object(x)
```

---

## OPA with Terraform

### Workflow Integration

```
1. terraform plan -out=tfplan.binary
2. terraform show -json tfplan.binary > tfplan.json
3. opa eval --data policy.rego --input tfplan.json "data.terraform.deny"
4. If no violations: terraform apply tfplan.binary
```

### Terraform Plan JSON Structure

```json
{
  "format_version": "1.0",
  "terraform_version": "1.9.0",
  "planned_values": {
    "root_module": {
      "resources": [
        {
          "address": "libvirt_network.main",
          "mode": "managed",
          "type": "libvirt_network",
          "name": "main",
          "values": {
            "name": "test-network",
            "mode": "nat",
            "addresses": ["192.168.100.0/24"]
          }
        }
      ]
    }
  },
  "resource_changes": [
    {
      "address": "libvirt_network.main",
      "mode": "managed",
      "type": "libvirt_network",
      "change": {
        "actions": ["create"],
        "after": {
          "name": "test-network",
          "mode": "nat"
        }
      }
    }
  ]
}
```

---

## Writing Your First Policy

### Example 1: Network Naming Convention

**Policy** (`network_naming.rego`):
```rego
package terraform.libvirt.naming

import future.keywords.if
import future.keywords.contains

# Deny networks without proper naming
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "libvirt_network"
    resource.change.actions[_] == "create"
    
    name := resource.change.after.name
    not startswith(name, "net-")
    
    msg := sprintf(
        "Network '%s' must start with 'net-' prefix",
        [name]
    )
}
```

**Test** (`network_naming_test.rego`):
```rego
package terraform.libvirt.naming

test_network_naming_valid {
    not deny with input as {
        "resource_changes": [{
            "type": "libvirt_network",
            "change": {
                "actions": ["create"],
                "after": {"name": "net-production"}
            }
        }]
    }
}

test_network_naming_invalid {
    deny with input as {
        "resource_changes": [{
            "type": "libvirt_network",
            "change": {
                "actions": ["create"],
                "after": {"name": "production"}
            }
        }]
    }
}
```

**Run Test**:
```bash
opa test network_naming.rego network_naming_test.rego -v
```

### Example 2: VM Resource Limits

**Policy** (`vm_limits.rego`):
```rego
package terraform.libvirt.resources

import future.keywords.if

# Minimum memory requirement
min_memory := 512

# Maximum memory limit
max_memory := 16384

# Deny VMs with insufficient memory
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "libvirt_domain"
    resource.change.actions[_] == "create"
    
    memory := resource.change.after.memory
    memory < min_memory
    
    msg := sprintf(
        "VM '%s' memory (%d MB) is below minimum (%d MB)",
        [resource.change.after.name, memory, min_memory]
    )
}

# Deny VMs exceeding memory limit
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "libvirt_domain"
    resource.change.actions[_] == "create"
    
    memory := resource.change.after.memory
    memory > max_memory
    
    msg := sprintf(
        "VM '%s' memory (%d MB) exceeds maximum (%d MB)",
        [resource.change.after.name, memory, max_memory]
    )
}

# Deny VMs with too many vCPUs
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "libvirt_domain"
    resource.change.actions[_] == "create"
    
    vcpu := resource.change.after.vcpu
    vcpu > 8
    
    msg := sprintf(
        "VM '%s' has too many vCPUs (%d), maximum is 8",
        [resource.change.after.name, vcpu]
    )
}
```

---

## Policy Structure and Organization

### Directory Structure

```
policies/
├── terraform/
│   ├── libvirt/
│   │   ├── naming.rego           # Naming conventions
│   │   ├── resources.rego        # Resource limits
│   │   ├── security.rego         # Security policies
│   │   └── compliance.rego       # Compliance rules
│   └── common/
│       ├── tagging.rego          # Tagging policies
│       └── helpers.rego          # Reusable functions
├── tests/
│   ├── naming_test.rego
│   ├── resources_test.rego
│   └── security_test.rego
└── data/
    ├── allowed_networks.json
    └── approved_images.json
```

### Package Organization

```rego
# Base package for all Terraform policies
package terraform

# Libvirt-specific policies
package terraform.libvirt

# Naming policies
package terraform.libvirt.naming

# Security policies
package terraform.libvirt.security
```

### Reusable Helper Functions

**helpers.rego**:
```rego
package terraform.helpers

import future.keywords.if

# Check if resource is being created
is_create(resource) if {
    resource.change.actions[_] == "create"
}

# Check if resource is being updated
is_update(resource) if {
    resource.change.actions[_] == "update"
}

# Check if resource is being deleted
is_delete(resource) if {
    resource.change.actions[_] == "delete"
}

# Get resource name safely
resource_name(resource) := name if {
    name := resource.change.after.name
} else := resource.address

# Check if string matches pattern
matches_pattern(str, pattern) if {
    regex.match(pattern, str)
}
```

---

## Common Policy Patterns

### Pattern 1: Allowed Values

```rego
package terraform.libvirt.network

import future.keywords.if

# Allowed network modes
allowed_modes := {"nat", "route", "bridge"}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "libvirt_network"
    
    mode := resource.change.after.mode
    not mode in allowed_modes
    
    msg := sprintf(
        "Network '%s' uses invalid mode '%s'. Allowed: %v",
        [resource.change.after.name, mode, allowed_modes]
    )
}
```

### Pattern 2: Required Fields

```rego
package terraform.libvirt.tagging

import future.keywords.if

# Required tags for all resources
required_tags := {"environment", "owner", "project"}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type in {"libvirt_network", "libvirt_domain", "libvirt_volume"}
    
    # Get tags from resource
    tags := object.keys(resource.change.after.tags)
    
    # Find missing tags
    missing := required_tags - tags
    count(missing) > 0
    
    msg := sprintf(
        "Resource '%s' is missing required tags: %v",
        [resource.address, missing]
    )
}
```

### Pattern 3: Conditional Policies

```rego
package terraform.libvirt.security

import future.keywords.if

# Production VMs must have specific settings
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "libvirt_domain"
    
    # Check if production environment
    tags := resource.change.after.tags
    tags.environment == "production"
    
    # Production VMs must have at least 2 vCPUs
    vcpu := resource.change.after.vcpu
    vcpu < 2
    
    msg := sprintf(
        "Production VM '%s' must have at least 2 vCPUs (has %d)",
        [resource.change.after.name, vcpu]
    )
}
```

### Pattern 4: Cross-Resource Validation

```rego
package terraform.libvirt.dependencies

import future.keywords.if

# Get all networks
networks[name] {
    resource := input.resource_changes[_]
    resource.type == "libvirt_network"
    name := resource.change.after.name
}

# Deny VMs without valid network
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "libvirt_domain"
    
    # Get network from VM
    network_name := resource.change.after.network_interface[_].network_name
    
    # Check if network exists
    not network_name in networks
    
    msg := sprintf(
        "VM '%s' references non-existent network '%s'",
        [resource.change.after.name, network_name]
    )
}
```

---

## Testing Policies

### Test Structure

```rego
package terraform.libvirt.naming

# Test valid case
test_valid_network_name {
    not deny with input as {
        "resource_changes": [{
            "type": "libvirt_network",
            "change": {
                "actions": ["create"],
                "after": {"name": "net-production"}
            }
        }]
    }
}

# Test invalid case
test_invalid_network_name {
    count(deny) > 0 with input as {
        "resource_changes": [{
            "type": "libvirt_network",
            "change": {
                "actions": ["create"],
                "after": {"name": "production"}
            }
        }]
    }
}

# Test multiple resources
test_mixed_network_names {
    violations := deny with input as {
        "resource_changes": [
            {
                "type": "libvirt_network",
                "change": {
                    "actions": ["create"],
                    "after": {"name": "net-valid"}
                }
            },
            {
                "type": "libvirt_network",
                "change": {
                    "actions": ["create"],
                    "after": {"name": "invalid"}
                }
            }
        ]
    }
    count(violations) == 1
}
```

### Running Tests

```bash
# Run all tests
opa test . -v

# Run specific test file
opa test naming_test.rego -v

# Run with coverage
opa test . --coverage

# Run with detailed output
opa test . -v --explain=full
```

### Test Coverage

```bash
# Generate coverage report
opa test . --coverage --format=json > coverage.json

# View coverage
opa test . --coverage
```

---

## Policy Enforcement Levels

### Advisory (Informational)

**Purpose**: Warn users without blocking

```rego
package terraform.advisory

warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "libvirt_domain"
    
    memory := resource.change.after.memory
    memory < 1024
    
    msg := sprintf(
        "ADVISORY: VM '%s' has low memory (%d MB). Consider increasing to 1024 MB or more.",
        [resource.change.after.name, memory]
    )
}
```

### Soft Mandatory (Can Override)

**Purpose**: Require justification to proceed

```rego
package terraform.soft_mandatory

# Can be overridden with approval
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "libvirt_domain"
    
    vcpu := resource.change.after.vcpu
    vcpu > 4
    
    # Check for override flag
    not input.override_approved
    
    msg := sprintf(
        "SOFT MANDATORY: VM '%s' has %d vCPUs (>4). Requires approval to proceed.",
        [resource.change.after.name, vcpu]
    )
}
```

### Hard Mandatory (Blocking)

**Purpose**: Cannot proceed without fixing

```rego
package terraform.hard_mandatory

# Cannot be overridden
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "libvirt_network"
    
    mode := resource.change.after.mode
    mode == "isolated"
    
    msg := sprintf(
        "HARD MANDATORY: Network '%s' cannot use 'isolated' mode. This is blocked by security policy.",
        [resource.change.after.name]
    )
}
```

---

## Sentinel Overview (Enterprise)

### What is Sentinel?

**HashiCorp Sentinel** is an enterprise policy-as-code framework integrated with:

- Terraform Cloud/Enterprise
- Vault Enterprise
- Consul Enterprise
- Nomad Enterprise

### Sentinel vs OPA

| Feature | OPA (Open Source) | Sentinel (Enterprise) |
|---------|-------------------|----------------------|
| **Cost** | Free | Paid (Enterprise) |
| **Language** | Rego | Sentinel |
| **Integration** | Manual | Native TFC/TFE |
| **UI** | CLI only | Web UI |
| **Policy Sets** | Manual | Managed |
| **Enforcement** | External | Built-in |
| **Testing** | OPA test | Sentinel test |

### Sentinel Example

```sentinel
import "tfplan/v2" as tfplan

# Allowed VM memory sizes
allowed_memory = [512, 1024, 2048, 4096, 8192]

# Main rule
main = rule {
    all tfplan.resource_changes as _, rc {
        rc.type is "libvirt_domain" implies
        rc.change.after.memory in allowed_memory
    }
}
```

### When to Use Each

**Use OPA when**:
- ✅ Open-source requirement
- ✅ Multi-tool policies (K8s, Terraform, etc.)
- ✅ Custom integrations needed
- ✅ Budget constraints

**Use Sentinel when**:
- ✅ Using Terraform Cloud/Enterprise
- ✅ Need native integration
- ✅ Want managed policy sets
- ✅ Enterprise support required

---

## Best Practices

### 1. Write Clear Error Messages

```rego
# ❌ Bad: Vague message
deny[msg] {
    resource.memory < 512
    msg := "Memory too low"
}

# ✅ Good: Specific message
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "libvirt_domain"
    memory := resource.change.after.memory
    memory < 512
    
    msg := sprintf(
        "VM '%s' memory (%d MB) is below minimum requirement (512 MB). Increase memory to at least 512 MB.",
        [resource.change.after.name, memory]
    )
}
```

### 2. Use Descriptive Package Names

```rego
# ❌ Bad: Generic
package policies

# ✅ Good: Specific
package terraform.libvirt.security.network
```

### 3. Separate Concerns

```rego
# ✅ Good: One policy per file
# naming.rego - Naming conventions
# security.rego - Security policies
# compliance.rego - Compliance rules
# resources.rego - Resource limits
```

### 4. Test Thoroughly

```rego
# Test valid cases
test_valid_config { ... }

# Test invalid cases
test_invalid_config { ... }

# Test edge cases
test_edge_cases { ... }

# Test multiple scenarios
test_complex_scenarios { ... }
```

### 5. Use External Data

```rego
# Load allowed values from file
allowed_networks := data.networks.approved

# Load configuration from JSON
config := data.config.libvirt
```

### 6. Version Control Policies

```bash
policies/
├── .git/
├── CHANGELOG.md
├── README.md
└── terraform/
    └── libvirt/
        ├── v1.0.0/
        ├── v1.1.0/
        └── v2.0.0/
```

---

## Hands-On Labs

### Lab 1: Basic Policy Development (20 minutes)

**Objective**: Write and test a basic OPA policy for Libvirt networks

**Tasks**:
1. Install OPA
2. Create a policy for network naming conventions
3. Write tests for the policy
4. Generate a Terraform plan and validate it

**Starter Policy** (`network_policy.rego`):
```rego
package terraform.libvirt

import future.keywords.if

# Networks must start with "net-" and end with environment
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "libvirt_network"
    
    name := resource.change.after.name
    not startswith(name, "net-")
    
    msg := sprintf("Network '%s' must start with 'net-'", [name])
}

# Networks must use NAT or route mode
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "libvirt_network"
    
    mode := resource.change.after.mode
    not mode in {"nat", "route"}
    
    msg := sprintf("Network '%s' must use 'nat' or 'route' mode (not '%s')", [name, mode])
}
```

**Your Task**: 
1. Add tests for valid and invalid cases
2. Create a Terraform configuration
3. Generate plan JSON
4. Validate with OPA

**Expected Output**:
```bash
$ opa test . -v
PASS: 4/4
```

---

### Lab 2: Resource Limits Policy (25 minutes)

**Objective**: Implement comprehensive resource limit policies

**Tasks**:
1. Create policies for VM memory and vCPU limits
2. Add volume size restrictions
3. Implement environment-specific rules
4. Test with multiple scenarios

**Starter Code** (`main.tf`):
```hcl
variable "environment" {
  type = string
}

resource "libvirt_domain" "vm" {
  name   = "vm-${var.environment}"
  memory = var.vm_memory
  vcpu   = var.vm_vcpu
  
  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "libvirt_volume" "disk" {
  name = "disk-${var.environment}"
  size = var.disk_size
}
```

**Your Task**: Create `resources.rego` with:
- Memory limits: 512 MB - 16 GB
- vCPU limits: 1-8 cores
- Production VMs: minimum 2 GB RAM, 2 vCPUs
- Development VMs: maximum 4 GB RAM, 2 vCPUs
- Volume size: 5 GB - 500 GB

**Expected Result**:
```bash
$ terraform plan -out=tfplan.binary
$ terraform show -json tfplan.binary > tfplan.json
$ opa eval --data resources.rego --input tfplan.json "data.terraform.libvirt.deny"
[]  # No violations
```

---

### Lab 3: Compliance Policy Suite (30 minutes)

**Objective**: Build a comprehensive compliance policy suite

**Tasks**:
1. Implement tagging requirements
2. Add naming conventions
3. Create security policies
4. Build policy test suite
5. Document policy decisions

**Requirements**:

**Tagging Policy**:
- All resources must have: `environment`, `owner`, `project`
- Production resources must have: `backup`, `monitoring`

**Naming Policy**:
- Networks: `net-<env>-<purpose>`
- VMs: `vm-<env>-<app>-<number>`
- Volumes: `vol-<env>-<purpose>`

**Security Policy**:
- No isolated networks
- Production VMs must have at least 2 network interfaces
- All volumes must be qcow2 format

**Your Task**: Create complete policy suite with:
- 3 policy files (tagging.rego, naming.rego, security.rego)
- Test files for each policy
- Integration test with full infrastructure
- Documentation of policy decisions

**Expected Result**:
```bash
$ opa test . --coverage
PASS: 15/15
Coverage: 95.2%
```

---

## Checkpoint Quiz

### Question 1: OPA vs Sentinel
**What is the primary difference between OPA and Sentinel?**

A) OPA is faster than Sentinel  
B) OPA is open-source, Sentinel is enterprise  
C) OPA only works with Kubernetes  
D) Sentinel uses Rego language

<details>
<summary>Show Answer</summary>

**Answer: B) OPA is open-source, Sentinel is enterprise**

**Explanation**: Open Policy Agent (OPA) is an open-source, general-purpose policy engine that can be used with any tool. HashiCorp Sentinel is an enterprise policy framework integrated with HashiCorp's enterprise products (Terraform Cloud/Enterprise, Vault, Consul, Nomad). OPA uses Rego language, while Sentinel uses its own Sentinel language.

</details>

---

### Question 2: Rego Language
**In Rego, what does the following expression do: `deny[msg] { ... }`?**

A) Creates a function named deny  
B) Defines a rule that collects violation messages  
C) Imports the deny module  
D) Declares a variable

<details>
<summary>Show Answer</summary>

**Answer: B) Defines a rule that collects violation messages**

**Explanation**: In Rego, `deny[msg]` is a rule that collects all violation messages into a set. Each time the rule body evaluates to true, the `msg` value is added to the `deny` set. This pattern is commonly used for policy violations where you want to collect all errors, not just the first one.

</details>

---

### Question 3: Policy Enforcement Levels
**Which enforcement level allows users to proceed with a justification?**

A) Advisory  
B) Soft Mandatory  
C) Hard Mandatory  
D) Critical

<details>
<summary>Show Answer</summary>

**Answer: B) Soft Mandatory**

**Explanation**: 
- **Advisory**: Warnings only, no blocking
- **Soft Mandatory**: Requires justification/approval to proceed
- **Hard Mandatory**: Cannot proceed, must fix violation

Soft mandatory policies allow flexibility for exceptional cases while still requiring explicit approval and documentation.

</details>

---

### Question 4: Testing Policies
**What command runs OPA policy tests with verbose output?**

A) `opa run -v`  
B) `opa test . -v`  
C) `opa validate --verbose`  
D) `opa check -v`

<details>
<summary>Show Answer</summary>

**Answer: B) `opa test . -v`**

**Explanation**: The `opa test` command runs policy tests. The `.` specifies the current directory, and `-v` enables verbose output showing which tests passed/failed. Other useful flags include `--coverage` for coverage reports and `--explain=full` for detailed explanations.

</details>

---

### Question 5: Terraform Integration
**What is the correct workflow for validating Terraform with OPA?**

A) terraform apply → opa eval → terraform plan  
B) opa eval → terraform plan → terraform apply  
C) terraform plan → terraform show -json → opa eval  
D) terraform init → opa eval → terraform plan

<details>
<summary>Show Answer</summary>

**Answer: C) terraform plan → terraform show -json → opa eval**

**Explanation**: The correct workflow is:
1. `terraform plan -out=tfplan.binary` - Create execution plan
2. `terraform show -json tfplan.binary > tfplan.json` - Convert to JSON
3. `opa eval --data policy.rego --input tfplan.json "data.terraform.deny"` - Validate
4. If no violations: `terraform apply tfplan.binary`

This ensures policies are checked before applying changes.

</details>

---

### Question 6: Best Practices
**Which is a best practice for writing policy error messages?**

A) Keep messages short and generic  
B) Include resource name, current value, and expected value  
C) Use technical jargon only  
D) Don't include any details

<details>
<summary>Show Answer</summary>

**Answer: B) Include resource name, current value, and expected value**

**Explanation**: Good error messages should be:
- **Specific**: Include resource name and address
- **Informative**: Show current vs expected values
- **Actionable**: Explain how to fix the issue
- **Clear**: Use plain language

Example: `"VM 'web-server' memory (256 MB) is below minimum requirement (512 MB). Increase memory to at least 512 MB."`

</details>

---

## Additional Resources

### Official Documentation
- [Open Policy Agent](https://www.openpolicyagent.org/)
- [Rego Language Reference](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [OPA Terraform Tutorial](https://www.openpolicyagent.org/docs/latest/terraform/)
- [HashiCorp Sentinel](https://docs.hashicorp.com/sentinel)

### Tools and Libraries
- [Conftest](https://www.conftest.dev/) - Test configuration files with OPA
- [Regula](https://regula.dev/) - Terraform security scanning with OPA
- [Terraform Compliance](https://terraform-compliance.com/) - BDD-style testing

### Community Resources
- [OPA Playground](https://play.openpolicyagent.org/) - Try Rego online
- [Policy Library](https://github.com/open-policy-agent/library) - Example policies
- [Styra Academy](https://academy.styra.com/) - OPA training

### Next Steps
- **PKR-100**: Packer Fundamentals (image building)
- **Cloud Modules**: Apply policies to AWS/Azure
- **Advanced OPA**: Custom functions, performance optimization

---

## Summary

In this course, you learned:

✅ **Policy as Code Concepts**: Why and when to use policy enforcement  
✅ **OPA Fundamentals**: Architecture, installation, and workflow  
✅ **Rego Language**: Syntax, data types, operators, and functions  
✅ **Policy Development**: Writing, testing, and organizing policies  
✅ **Common Patterns**: Allowed values, required fields, conditionals  
✅ **Enforcement Levels**: Advisory, soft mandatory, hard mandatory  
✅ **Sentinel Overview**: Enterprise alternative to OPA  
✅ **Best Practices**: Clear messages, testing, version control

### Key Takeaways

1. **Shift-Left Security**: Catch issues before deployment
2. **Declarative Policies**: Describe what should be true, not how
3. **Test Everything**: Policies are code, treat them as such
4. **Clear Communication**: Error messages should guide users
5. **Flexible Enforcement**: Use appropriate levels for different policies

### What's Next?

**Congratulations!** You've completed the TF-300 Advanced Terraform series. Continue to:

- **PKR-100**: Packer Fundamentals - Build custom VM images
- **Cloud Modules**: Apply your skills to AWS/Azure
- **Production**: Implement policies in your organization

---

**Course**: TF-300 Advanced Terraform  
**Module**: TF-304 - Policy as Code (OPA/Rego)  
**Duration**: 1 hour  
**Last Updated**: 2026-02-26
