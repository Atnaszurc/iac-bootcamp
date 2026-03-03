# TF-303: Terraform Test Framework

**Course**: TF-300 Advanced Terraform  
**Module**: TF-303  
**Duration**: 1 hour  
**Prerequisites**: TF-302 (Pre/Post Conditions & Check Blocks)  
**Terraform Version**: 1.6+ (Test Framework), 1.7+ (Mock Providers), 1.11+ (JUnit XML, state_key, override_during), 1.12+ (Parallelism), 1.13+ (File-level variables)

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Introduction to Terraform Testing](#introduction-to-terraform-testing)
4. [Test File Structure](#test-file-structure)
5. [Writing Basic Tests](#writing-basic-tests)
6. [Test Commands: Plan vs Apply](#test-commands-plan-vs-apply)
7. [Multiple Assertions](#multiple-assertions)
8. [Variables in Tests](#variables-in-tests)
9. [Mock Providers (Terraform 1.7+)](#mock-providers-terraform-17)
10. [Test Organization Strategies](#test-organization-strategies)
11. [Integration vs Unit Testing](#integration-vs-unit-testing)
12. [Testing Best Practices](#testing-best-practices)
13. [Common Testing Patterns](#common-testing-patterns)
14. [Debugging Failed Tests](#debugging-failed-tests)
15. [Advanced Features (1.11–1.13)](#advanced-features-111113)
16. [CI/CD Integration](#cicd-integration)
17. [Hands-On Labs](#hands-on-labs)
18. [Checkpoint Quiz](#checkpoint-quiz)
19. [Additional Resources](#additional-resources)

---

## Course Overview

Terraform 1.6 introduced a native testing framework that allows you to validate your infrastructure code without risking existing resources. This course covers writing, organizing, and running tests for Terraform configurations using the Libvirt provider.

### What You'll Build

- Test files for Libvirt networks, volumes, and VMs
- Unit tests with mock providers
- Integration tests with real infrastructure
- Comprehensive test suites for modules

### Why Testing Matters

- **Catch Errors Early**: Find configuration issues before deployment
- **Refactoring Confidence**: Change code safely with test coverage
- **Documentation**: Tests serve as executable documentation
- **Quality Assurance**: Ensure infrastructure meets requirements
- **Regression Prevention**: Prevent bugs from reappearing

---

## Learning Objectives

By the end of this course, you will be able to:

1. ✅ Write Terraform test files (`.tftest.hcl`)
2. ✅ Create assertions to validate resource properties
3. ✅ Use `plan` and `apply` commands in tests
4. ✅ Implement mock providers for unit testing
5. ✅ Organize tests for maintainability
6. ✅ Distinguish between unit and integration tests
7. ✅ Debug failing tests effectively
8. ✅ Apply testing best practices

---

## Introduction to Terraform Testing

### The Testing Pyramid

```
        /\
       /  \      Unit Tests (Mock Providers)
      /____\     - Fast, isolated
     /      \    - Test logic, not infrastructure
    /________\   Integration Tests (Real Provider)
   /          \  - Slower, comprehensive
  /____________\ - Test actual infrastructure
```

### Test Framework Features (Terraform 1.6+)

- **Native Testing**: Built into Terraform CLI
- **Declarative Tests**: HCL-based test definitions
- **Assertions**: Validate resource properties
- **Multiple Run Blocks**: Test different scenarios
- **Mock Providers**: Test without real infrastructure (1.7+)

### When to Write Tests

- ✅ **Always**: For reusable modules
- ✅ **Recommended**: For complex configurations
- ✅ **Optional**: For simple, one-off resources
- ✅ **Critical**: Before refactoring existing code

---

## Test File Structure

### File Naming Convention

```
my-module/
├── main.tf
├── variables.tf
├── outputs.tf
├── tests/
│   ├── basic.tftest.hcl          # Basic functionality
│   ├── validation.tftest.hcl     # Input validation
│   ├── integration.tftest.hcl    # Full integration
│   └── mocks/
│       └── libvirt.tfmock.hcl    # Mock data
```

### Basic Test File Structure

```hcl
# tests/basic.tftest.hcl

# Global variables (optional)
variables {
  network_name = "test-network"
  domain       = "test.local"
}

# Test run block
run "verify_network_creation" {
  command = plan
  
  assert {
    condition     = libvirt_network.main.name == var.network_name
    error_message = "Network name does not match expected value"
  }
}
```

### Test File Components

1. **Variables Block**: Define test inputs
2. **Run Blocks**: Individual test scenarios
3. **Assert Blocks**: Validation conditions
4. **Mock Providers**: Simulate infrastructure (optional)

---

## Writing Basic Tests

### Example 1: Test Libvirt Network

**Configuration** (`main.tf`):
```hcl
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "network_name" {
  type        = string
  description = "Name of the network"
}

variable "network_cidr" {
  type        = string
  description = "CIDR block for the network"
  default     = "192.168.100.0/24"
}

resource "libvirt_network" "main" {
  name      = var.network_name
  mode      = "nat"
  domain    = "test.local"
  addresses = [var.network_cidr]
  
  autostart = true
  
  dns {
    enabled = true
  }
}

output "network_id" {
  value = libvirt_network.main.id
}

output "network_bridge" {
  value = libvirt_network.main.bridge
}
```

**Test File** (`tests/network.tftest.hcl`):
```hcl
variables {
  network_name = "test-network"
  network_cidr = "192.168.100.0/24"
}

run "verify_network_properties" {
  command = plan
  
  assert {
    condition     = libvirt_network.main.name == var.network_name
    error_message = "Network name does not match expected value"
  }
  
  assert {
    condition     = libvirt_network.main.mode == "nat"
    error_message = "Network mode should be 'nat'"
  }
  
  assert {
    condition     = libvirt_network.main.autostart == true
    error_message = "Network autostart should be enabled"
  }
  
  assert {
    condition     = contains(libvirt_network.main.addresses, var.network_cidr)
    error_message = "Network CIDR not found in addresses"
  }
}
```

### Example 2: Test Libvirt Volume

**Configuration** (`main.tf`):
```hcl
variable "volume_name" {
  type = string
}

variable "volume_size" {
  type    = number
  default = 10737418240 # 10 GB
}

resource "libvirt_volume" "main" {
  name   = var.volume_name
  pool   = "default"
  size   = var.volume_size
  format = "qcow2"
}

output "volume_id" {
  value = libvirt_volume.main.id
}
```

**Test File** (`tests/volume.tftest.hcl`):
```hcl
variables {
  volume_name = "test-volume"
  volume_size = 10737418240
}

run "verify_volume_creation" {
  command = plan
  
  assert {
    condition     = libvirt_volume.main.name == var.volume_name
    error_message = "Volume name does not match"
  }
  
  assert {
    condition     = libvirt_volume.main.format == "qcow2"
    error_message = "Volume format should be qcow2"
  }
  
  assert {
    condition     = libvirt_volume.main.size == var.volume_size
    error_message = "Volume size does not match expected value"
  }
}
```

---

## Test Commands: Plan vs Apply

### Using `command = plan`

**Best For**: Fast unit tests, validation logic

```hcl
run "test_with_plan" {
  command = plan  # Only generates execution plan
  
  assert {
    condition     = libvirt_network.main.name == "test-net"
    error_message = "Network name validation failed"
  }
}
```

**Advantages**:
- ⚡ Fast execution
- 💰 No infrastructure costs
- 🔒 Safe (no changes)

**Limitations**:
- ❌ Cannot test computed values
- ❌ Cannot verify actual creation
- ❌ Cannot test dependencies

### Using `command = apply`

**Best For**: Integration tests, end-to-end validation

```hcl
run "test_with_apply" {
  command = apply  # Actually creates infrastructure
  
  assert {
    condition     = libvirt_network.main.id != ""
    error_message = "Network ID should be populated after creation"
  }
  
  assert {
    condition     = libvirt_network.main.bridge != ""
    error_message = "Network bridge should be assigned"
  }
}
```

**Advantages**:
- ✅ Tests actual creation
- ✅ Validates computed values
- ✅ Tests real dependencies

**Limitations**:
- 🐌 Slower execution
- 💾 Requires cleanup
- ⚠️ May affect system state

### Choosing Between Plan and Apply

| Scenario | Use Plan | Use Apply |
|----------|----------|-----------|
| Validate input logic | ✅ | ❌ |
| Test computed values | ❌ | ✅ |
| Fast feedback loop | ✅ | ❌ |
| Integration testing | ❌ | ✅ |
| CI/CD pipelines | ✅ (unit) | ✅ (integration) |
| Local development | ✅ | ⚠️ (careful) |

---

## Multiple Assertions

### Grouping Related Assertions

```hcl
run "verify_vm_configuration" {
  command = plan
  
  # CPU assertions
  assert {
    condition     = libvirt_domain.vm.vcpu >= 1
    error_message = "VM must have at least 1 vCPU"
  }
  
  assert {
    condition     = libvirt_domain.vm.vcpu <= 8
    error_message = "VM cannot exceed 8 vCPUs"
  }
  
  # Memory assertions
  assert {
    condition     = libvirt_domain.vm.memory >= 512
    error_message = "VM must have at least 512 MB RAM"
  }
  
  assert {
    condition     = libvirt_domain.vm.memory <= 16384
    error_message = "VM cannot exceed 16 GB RAM"
  }
  
  # Network assertions
  assert {
    condition     = length(libvirt_domain.vm.network_interface) > 0
    error_message = "VM must have at least one network interface"
  }
}
```

### Testing Collections

```hcl
run "verify_multiple_volumes" {
  command = plan
  
  # Test that all volumes are created
  assert {
    condition     = length(libvirt_volume.data) == 3
    error_message = "Expected 3 data volumes"
  }
  
  # Test that all volumes use qcow2
  assert {
    condition = alltrue([
      for v in libvirt_volume.data : v.format == "qcow2"
    ])
    error_message = "All volumes must use qcow2 format"
  }
  
  # Test volume sizes
  assert {
    condition = alltrue([
      for v in libvirt_volume.data : v.size >= 1073741824
    ])
    error_message = "All volumes must be at least 1 GB"
  }
}
```

---

## Variables in Tests

### Global Variables

```hcl
# Shared across all run blocks
variables {
  environment = "test"
  region      = "local"
  base_cidr   = "192.168.0.0/16"
}

run "test_dev_network" {
  command = plan
  
  # Uses global variables
  assert {
    condition     = libvirt_network.main.domain == "${var.environment}.local"
    error_message = "Domain should include environment"
  }
}

run "test_prod_network" {
  # Override global variable for this run
  variables {
    environment = "prod"
  }
  
  command = plan
  
  assert {
    condition     = libvirt_network.main.domain == "prod.local"
    error_message = "Production domain incorrect"
  }
}
```

### Per-Run Variables

```hcl
run "test_small_vm" {
  variables {
    vm_memory = 1024
    vm_vcpu   = 1
  }
  
  command = plan
  
  assert {
    condition     = libvirt_domain.vm.memory == 1024
    error_message = "Small VM memory incorrect"
  }
}

run "test_large_vm" {
  variables {
    vm_memory = 8192
    vm_vcpu   = 4
  }
  
  command = plan
  
  assert {
    condition     = libvirt_domain.vm.memory == 8192
    error_message = "Large VM memory incorrect"
  }
}
```

---

## Mock Providers (Terraform 1.7+)

### Why Use Mock Providers?

- ⚡ **Speed**: No actual infrastructure creation
- 🔒 **Safety**: No system changes
- 💰 **Cost**: Zero infrastructure costs
- 🧪 **Isolation**: Test logic independently

### Basic Mock Provider

```hcl
# tests/unit.tftest.hcl

mock_provider "libvirt" {}

variables {
  network_name = "mock-network"
}

run "test_network_logic" {
  command = plan
  
  assert {
    condition     = libvirt_network.main.name == var.network_name
    error_message = "Network name logic failed"
  }
}
```

### Mock Provider with Defaults

```hcl
mock_provider "libvirt" {
  mock_resource "libvirt_network" {
    defaults = {
      id     = "mock-network-id-12345"
      name   = "mock-network"
      bridge = "virbr1"
      mode   = "nat"
    }
  }
  
  mock_resource "libvirt_volume" {
    defaults = {
      id     = "mock-volume-id-67890"
      name   = "mock-volume"
      format = "qcow2"
      size   = 10737418240
    }
  }
}

run "test_with_mocks" {
  command = plan
  
  # Can test computed values with mocks
  assert {
    condition     = libvirt_network.main.id != ""
    error_message = "Network ID should be populated"
  }
  
  assert {
    condition     = libvirt_network.main.bridge != ""
    error_message = "Bridge should be assigned"
  }
}
```

### External Mock Files

**Mock File** (`tests/mocks/libvirt.tfmock.hcl`):
```hcl
mock_resource "libvirt_network" {
  defaults = {
    id        = "mock-net-id"
    name      = "mock-network"
    bridge    = "virbr1"
    mode      = "nat"
    addresses = ["192.168.100.0/24"]
    autostart = true
  }
}

mock_resource "libvirt_volume" {
  defaults = {
    id     = "mock-vol-id"
    name   = "mock-volume"
    format = "qcow2"
    size   = 10737418240
  }
}

mock_resource "libvirt_domain" {
  defaults = {
    id     = "mock-vm-id"
    name   = "mock-vm"
    vcpu   = 2
    memory = 2048
  }
}
```

**Test File** (`tests/unit.tftest.hcl`):
```hcl
mock_provider "libvirt" {
  source = "./mocks/libvirt.tfmock.hcl"
}

run "test_with_external_mocks" {
  command = plan
  
  assert {
    condition     = libvirt_domain.vm.vcpu == 2
    error_message = "VM vCPU count incorrect"
  }
}
```

---

## Test Organization Strategies

### Strategy 1: By Feature

```
tests/
├── network.tftest.hcl      # Network-related tests
├── storage.tftest.hcl      # Storage-related tests
├── compute.tftest.hcl      # VM-related tests
└── integration.tftest.hcl  # Full stack tests
```

### Strategy 2: By Test Type

```
tests/
├── unit/
│   ├── network.tftest.hcl
│   └── volume.tftest.hcl
├── integration/
│   └── full-stack.tftest.hcl
└── mocks/
    └── libvirt.tfmock.hcl
```

### Strategy 3: By Scenario

```
tests/
├── basic-vm.tftest.hcl           # Simple VM
├── multi-vm.tftest.hcl           # Multiple VMs
├── custom-network.tftest.hcl     # Custom networking
└── high-availability.tftest.hcl  # HA setup
```

---

## Integration vs Unit Testing

### Unit Tests (Mock Providers)

**Purpose**: Test configuration logic

```hcl
# tests/unit/network-logic.tftest.hcl

mock_provider "libvirt" {}

variables {
  environment = "dev"
  network_prefix = "192.168"
}

run "test_network_naming" {
  command = plan
  
  assert {
    condition     = libvirt_network.main.name == "${var.environment}-network"
    error_message = "Network naming logic failed"
  }
}

run "test_cidr_calculation" {
  command = plan
  
  assert {
    condition     = libvirt_network.main.addresses[0] == "${var.network_prefix}.100.0/24"
    error_message = "CIDR calculation failed"
  }
}
```

### Integration Tests (Real Provider)

**Purpose**: Test actual infrastructure creation

```hcl
# tests/integration/full-stack.tftest.hcl

variables {
  network_name = "integration-test-net"
  vm_name      = "integration-test-vm"
}

run "create_network" {
  command = apply
  
  assert {
    condition     = libvirt_network.main.id != ""
    error_message = "Network was not created"
  }
  
  assert {
    condition     = libvirt_network.main.bridge != ""
    error_message = "Network bridge not assigned"
  }
}

run "create_vm" {
  command = apply
  
  assert {
    condition     = libvirt_domain.vm.id != ""
    error_message = "VM was not created"
  }
  
  assert {
    condition     = length(libvirt_domain.vm.network_interface) > 0
    error_message = "VM has no network interfaces"
  }
}
```

### Comparison Table

| Aspect | Unit Tests | Integration Tests |
|--------|------------|-------------------|
| **Speed** | Fast (seconds) | Slow (minutes) |
| **Provider** | Mock | Real |
| **Command** | `plan` | `apply` |
| **Isolation** | High | Low |
| **Confidence** | Logic only | Full stack |
| **CI/CD** | Every commit | Pre-merge |
| **Cleanup** | Not needed | Required |

---

## Testing Best Practices

### 1. Write Descriptive Test Names

```hcl
# ❌ Bad: Vague name
run "test1" {
  command = plan
  assert {
    condition = libvirt_network.main.name == "test"
    error_message = "Failed"
  }
}

# ✅ Good: Descriptive name
run "verify_network_uses_nat_mode_for_internet_access" {
  command = plan
  assert {
    condition     = libvirt_network.main.mode == "nat"
    error_message = "Network must use NAT mode for internet access"
  }
}
```

### 2. Write Clear Error Messages

```hcl
# ❌ Bad: Generic message
assert {
  condition     = libvirt_domain.vm.memory >= 1024
  error_message = "Memory check failed"
}

# ✅ Good: Specific message
assert {
  condition     = libvirt_domain.vm.memory >= 1024
  error_message = "VM memory must be at least 1024 MB (1 GB). Current: ${libvirt_domain.vm.memory} MB"
}
```

### 3. Test Both Success and Failure

```hcl
# Test valid configuration
run "valid_network_cidr" {
  variables {
    network_cidr = "192.168.100.0/24"
  }
  
  command = plan
  
  assert {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/\\d+$", var.network_cidr))
    error_message = "Valid CIDR should pass"
  }
}

# Test invalid configuration (expect failure)
run "invalid_network_cidr" {
  variables {
    network_cidr = "invalid-cidr"
  }
  
  command = plan
  expect_failures = [
    var.network_cidr
  ]
}
```

### 4. Use Variables for Flexibility

```hcl
# ❌ Bad: Hard-coded values
run "test_network" {
  command = plan
  assert {
    condition     = libvirt_network.main.name == "my-network"
    error_message = "Name mismatch"
  }
}

# ✅ Good: Parameterized
variables {
  network_name = "test-network"
}

run "test_network" {
  command = plan
  assert {
    condition     = libvirt_network.main.name == var.network_name
    error_message = "Network name should match input variable"
  }
}
```

### 5. Group Related Assertions

```hcl
# ✅ Good: Logical grouping
run "verify_vm_resource_limits" {
  command = plan
  
  # CPU limits
  assert {
    condition     = libvirt_domain.vm.vcpu >= 1 && libvirt_domain.vm.vcpu <= 8
    error_message = "vCPU must be between 1 and 8"
  }
  
  # Memory limits
  assert {
    condition     = libvirt_domain.vm.memory >= 512 && libvirt_domain.vm.memory <= 16384
    error_message = "Memory must be between 512 MB and 16 GB"
  }
}
```

### 6. Keep Tests Independent

```hcl
# ❌ Bad: Tests depend on each other
run "create_network" {
  command = apply
}

run "create_vm" {
  # Assumes network from previous test exists
  command = apply
}

# ✅ Good: Each test is self-contained
run "create_network_and_vm" {
  command = apply
  
  assert {
    condition     = libvirt_network.main.id != ""
    error_message = "Network creation failed"
  }
  
  assert {
    condition     = libvirt_domain.vm.id != ""
    error_message = "VM creation failed"
  }
}
```

---

## Common Testing Patterns

### Pattern 1: Testing Resource Counts

```hcl
run "verify_vm_count" {
  variables {
    vm_count = 3
  }
  
  command = plan
  
  assert {
    condition     = length(libvirt_domain.vms) == var.vm_count
    error_message = "Expected ${var.vm_count} VMs, got ${length(libvirt_domain.vms)}"
  }
}
```

### Pattern 2: Testing Conditional Resources

```hcl
run "test_monitoring_enabled" {
  variables {
    enable_monitoring = true
  }
  
  command = plan
  
  assert {
    condition     = length(libvirt_volume.monitoring) == 1
    error_message = "Monitoring volume should exist when enabled"
  }
}

run "test_monitoring_disabled" {
  variables {
    enable_monitoring = false
  }
  
  command = plan
  
  assert {
    condition     = length(libvirt_volume.monitoring) == 0
    error_message = "Monitoring volume should not exist when disabled"
  }
}
```

### Pattern 3: Testing Computed Values

```hcl
run "test_computed_values" {
  command = apply
  
  # Test that ID is generated
  assert {
    condition     = libvirt_network.main.id != ""
    error_message = "Network ID should be computed after creation"
  }
  
  # Test that bridge is assigned
  assert {
    condition     = can(regex("^virbr\\d+$", libvirt_network.main.bridge))
    error_message = "Bridge name should follow virbr<N> pattern"
  }
}
```

### Pattern 4: Testing Module Outputs

```hcl
run "test_module_outputs" {
  command = plan
  
  assert {
    condition     = output.network_id != ""
    error_message = "Module should output network_id"
  }
  
  assert {
    condition     = output.network_cidr != ""
    error_message = "Module should output network_cidr"
  }
  
  assert {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/\\d+$", output.network_cidr))
    error_message = "network_cidr output should be valid CIDR"
  }
}
```

---

## Debugging Failed Tests

### Understanding Test Output

```bash
$ terraform test

tests/network.tftest.hcl... in progress
  run "verify_network_properties"... fail
╷
│ Error: Test assertion failed
│ 
│   on tests/network.tftest.hcl line 12, in run "verify_network_properties":
│   12:     condition     = libvirt_network.main.mode == "bridge"
│ 
│ Network mode should be 'nat'
│ 
│ Expected: bridge
│ Actual: nat
╵

tests/network.tftest.hcl... fail

Failure! 0 passed, 1 failed.
```

### Debugging Strategies

#### 1. Add Debug Outputs

```hcl
run "debug_network_config" {
  command = plan
  
  # Temporary debug assertion
  assert {
    condition     = false  # Always fails to show value
    error_message = "DEBUG: Network mode is '${libvirt_network.main.mode}'"
  }
}
```

#### 2. Test Incrementally

```hcl
# Start simple
run "test_network_exists" {
  command = plan
  assert {
    condition     = libvirt_network.main != null
    error_message = "Network resource should exist"
  }
}

# Add more assertions
run "test_network_name" {
  command = plan
  assert {
    condition     = libvirt_network.main.name == var.network_name
    error_message = "Network name mismatch"
  }
}

# Test complex properties
run "test_network_full_config" {
  command = plan
  # ... all assertions
}
```

#### 3. Use `terraform console`

```bash
# After a failed test, inspect state
terraform console

> libvirt_network.main
{
  "addresses" = ["192.168.100.0/24"]
  "mode" = "nat"
  "name" = "test-network"
  # ...
}
```

#### 4. Isolate the Problem

```hcl
# Comment out assertions to find the failing one
run "test_network" {
  command = plan
  
  assert {
    condition     = libvirt_network.main.name == var.network_name
    error_message = "Name check"
  }
  
  # assert {
  #   condition     = libvirt_network.main.mode == "bridge"
  #   error_message = "Mode check"
  # }
}
```

---

## Hands-On Labs

### Lab 1: Basic Network Testing (15 minutes)

**Objective**: Write tests for a Libvirt network configuration

**Tasks**:
1. Create a network configuration with variables
2. Write a test file with multiple assertions
3. Test with both `plan` and `apply` commands
4. Verify network properties (name, mode, CIDR, autostart)

**Starter Code** (`main.tf`):
```hcl
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "network_name" {
  type = string
}

variable "network_cidr" {
  type    = string
  default = "192.168.100.0/24"
}

resource "libvirt_network" "main" {
  name      = var.network_name
  mode      = "nat"
  domain    = "lab1.local"
  addresses = [var.network_cidr]
  autostart = true
  
  dns {
    enabled = true
  }
}

output "network_id" {
  value = libvirt_network.main.id
}
```

**Your Task**: Create `tests/network.tftest.hcl` with:
- Global variables for network_name and network_cidr
- A `plan` test verifying all properties
- An `apply` test verifying computed values (id, bridge)

**Expected Result**:
```bash
$ terraform test
tests/network.tftest.hcl... in progress
  run "verify_network_plan"... pass
  run "verify_network_apply"... pass
tests/network.tftest.hcl... pass

Success! 2 passed, 0 failed.
```

---

### Lab 2: Mock Provider Testing (20 minutes)

**Objective**: Use mock providers for unit testing

**Tasks**:
1. Create a VM module with network and storage
2. Write unit tests using mock providers
3. Create a separate mock data file
4. Test configuration logic without creating infrastructure

**Starter Code** (`main.tf`):
```hcl
variable "vm_name" {
  type = string
}

variable "vm_memory" {
  type    = number
  default = 2048
}

variable "vm_vcpu" {
  type    = number
  default = 2
}

variable "network_name" {
  type = string
}

resource "libvirt_network" "vm_network" {
  name      = var.network_name
  mode      = "nat"
  addresses = ["192.168.200.0/24"]
}

resource "libvirt_volume" "vm_disk" {
  name   = "${var.vm_name}-disk"
  pool   = "default"
  size   = 10737418240
  format = "qcow2"
}

resource "libvirt_domain" "vm" {
  name   = var.vm_name
  memory = var.vm_memory
  vcpu   = var.vm_vcpu
  
  network_interface {
    network_id = libvirt_network.vm_network.id
  }
  
  disk {
    volume_id = libvirt_volume.vm_disk.id
  }
}

output "vm_id" {
  value = libvirt_domain.vm.id
}
```

**Your Task**:
1. Create `tests/mocks/libvirt.tfmock.hcl` with mock data
2. Create `tests/unit.tftest.hcl` using the mock provider
3. Test VM naming, resource limits, and network configuration
4. Verify tests run without creating real infrastructure

**Expected Result**:
```bash
$ terraform test
tests/unit.tftest.hcl... in progress
  run "test_vm_naming"... pass
  run "test_resource_limits"... pass
  run "test_network_config"... pass
tests/unit.tftest.hcl... pass

Success! 3 passed, 0 failed.
```

---

### Lab 3: Integration Testing (30 minutes)

**Objective**: Write comprehensive integration tests

**Tasks**:
1. Create a multi-VM infrastructure
2. Write integration tests that actually create resources
3. Test dependencies between resources
4. Verify computed values and relationships

**Starter Code** (`main.tf`):
```hcl
variable "environment" {
  type = string
}

variable "vm_count" {
  type    = number
  default = 2
}

resource "libvirt_network" "main" {
  name      = "${var.environment}-network"
  mode      = "nat"
  addresses = ["192.168.150.0/24"]
  autostart = true
}

resource "libvirt_volume" "vm_disks" {
  count  = var.vm_count
  name   = "${var.environment}-vm-${count.index}-disk"
  pool   = "default"
  size   = 5368709120  # 5 GB
  format = "qcow2"
}

resource "libvirt_domain" "vms" {
  count  = var.vm_count
  name   = "${var.environment}-vm-${count.index}"
  memory = 1024
  vcpu   = 1
  
  network_interface {
    network_id = libvirt_network.main.id
  }
  
  disk {
    volume_id = libvirt_volume.vm_disks[count.index].id
  }
}

output "vm_ids" {
  value = libvirt_domain.vms[*].id
}

output "network_bridge" {
  value = libvirt_network.main.bridge
}
```

**Your Task**: Create `tests/integration.tftest.hcl` with:
- Tests for network creation
- Tests for volume creation (count and properties)
- Tests for VM creation (count and configuration)
- Tests for resource relationships
- Cleanup verification

**Expected Result**:
```bash
$ terraform test
tests/integration.tftest.hcl... in progress
  run "create_network"... pass
  run "create_volumes"... pass
  run "create_vms"... pass
  run "verify_relationships"... pass
tests/integration.tftest.hcl... pass

Success! 4 passed, 0 failed.
```

---

## Checkpoint Quiz

Test your understanding of the Terraform Test Framework:

### Question 1: Test File Extension
**What file extension is used for Terraform test files?**

A) `.tf`  
B) `.tftest`  
C) `.tftest.hcl`  
D) `.test.hcl`

<details>
<summary>Show Answer</summary>

**Answer: C) `.tftest.hcl`**

**Explanation**: Terraform test files use the `.tftest.hcl` extension. This distinguishes them from regular Terraform configuration files (`.tf`) and allows Terraform to identify and execute them with the `terraform test` command.

</details>

---

### Question 2: Plan vs Apply
**When should you use `command = plan` instead of `command = apply` in a test?**

A) When you want to test computed values  
B) When you want fast unit tests without creating infrastructure  
C) When you need to verify resource dependencies  
D) When testing in production

<details>
<summary>Show Answer</summary>

**Answer: B) When you want fast unit tests without creating infrastructure**

**Explanation**: `command = plan` only generates an execution plan without creating actual infrastructure. This makes tests faster and safer for unit testing configuration logic. Use `command = apply` when you need to test computed values, actual resource creation, or dependencies (options A and C).

</details>

---

### Question 3: Mock Providers
**What is the primary benefit of using mock providers in Terraform tests?**

A) They make tests slower but more accurate  
B) They allow testing without creating real infrastructure  
C) They are required for all Terraform tests  
D) They only work with cloud providers

<details>
<summary>Show Answer</summary>

**Answer: B) They allow testing without creating real infrastructure**

**Explanation**: Mock providers (introduced in Terraform 1.7) simulate infrastructure resources without actually creating them. This enables fast, safe unit testing of configuration logic without system changes or costs. They work with any provider, including Libvirt.

</details>

---

### Question 4: Assertion Error Messages
**What makes a good error message in a test assertion?**

A) Short and generic  
B) Specific with actual vs expected values  
C) Technical jargon only  
D) No message needed

<details>
<summary>Show Answer</summary>

**Answer: B) Specific with actual vs expected values**

**Explanation**: Good error messages are specific and include context about what was expected versus what was found. For example: `"VM memory must be at least 1024 MB. Current: ${libvirt_domain.vm.memory} MB"` is much more helpful than `"Memory check failed"`.

</details>

---

### Question 5: Test Organization
**Which test organization strategy separates unit tests from integration tests?**

A) By feature (network.tftest.hcl, storage.tftest.hcl)  
B) By test type (unit/, integration/)  
C) By scenario (basic-vm.tftest.hcl, multi-vm.tftest.hcl)  
D) All tests in one file

<details>
<summary>Show Answer</summary>

**Answer: B) By test type (unit/, integration/)**

**Explanation**: Organizing tests by type (unit/ and integration/ directories) clearly separates fast unit tests (using mocks) from slower integration tests (using real infrastructure). This makes it easy to run different test suites in different contexts (e.g., unit tests on every commit, integration tests before merging).

</details>

---

### Question 6: Testing Best Practices
**Which of the following is a testing best practice?**

A) Hard-code all values in tests  
B) Make tests depend on each other  
C) Write descriptive test names and clear error messages  
D) Only test successful scenarios

<details>
<summary>Show Answer</summary>

**Answer: C) Write descriptive test names and clear error messages**

**Explanation**: Best practices include:
- Descriptive test names (e.g., `verify_network_uses_nat_mode_for_internet_access`)
- Clear error messages with context
- Parameterized tests using variables (not hard-coded)
- Independent tests (not dependent on each other)
- Testing both success and failure scenarios

Options A, B, and D are anti-patterns that make tests harder to maintain and less reliable.

</details>

---

## Advanced Features (1.11–1.13)

### JUnit XML Output (Terraform 1.11+ GA)

The `-junit-xml` flag produces test results in JUnit XML format for CI/CD integration:

```bash
# Generate JUnit XML output
terraform test -junit-xml=results.xml

# Combine with verbose output
terraform test -verbose -junit-xml=results.xml
```

See **[tests/ci-integration.md](example/tests/ci-integration.md)** for full GitHub Actions and Azure DevOps examples.

---

### `override_during = plan` (Terraform 1.15+)

> **⚠️ Version Note**: While this feature was announced for Terraform 1.11+, it is not available in Terraform 1.14.x. It requires Terraform 1.15 or later.

Before 1.15, `mock_provider` overrides only applied during the **apply** phase. Terraform 1.15 added `override_during = plan` to apply mocks at plan time — enabling true unit testing with zero provider interaction:

```hcl
mock_provider "local" {
  mock_resource "local_file" {
    defaults = { id = "mock-id" }
  }
}

run "pure_unit_test" {
  command = plan

  # override_during = plan: mock applies at plan time (Terraform 1.11+)
  # No provider is consulted — not even for plan validation.
  override_during = plan

  assert {
    condition     = output.environment == "dev"
    error_message = "Expected environment 'dev'"
  }
}
```

| `override_during` | Behaviour |
|-------------------|-----------|
| `apply` (default) | Mock applies during apply; real provider consulted during plan |
| `plan` (1.11+) | Mock applies during plan AND apply — zero provider interaction |

---

### `state_key` — Shared State Between Runs (Terraform 1.11+)

By default, each `run` block gets isolated state. `state_key` allows multiple run blocks to share state — enabling multi-step test scenarios:

```hcl
run "create_base_resources" {
  command   = apply
  state_key = "shared"   # State stored under "shared"

  assert {
    condition     = output.service_count == 1
    error_message = "Expected 1 service"
  }
}

run "add_more_resources" {
  command   = plan
  state_key = "shared"   # Sees state from "create_base_resources"

  variables {
    # Add more services to the existing configuration
  }

  assert {
    condition     = output.service_count == 2
    error_message = "Expected 2 services after adding one"
  }
}
```

**When to use `state_key`**:
- Multi-step scenarios where later runs build on earlier ones
- Testing incremental changes to infrastructure
- Verifying that updates don't destroy existing resources

**When NOT to use `state_key`**:
- Parallel test execution (state conflicts)
- Independent test scenarios (use isolated state instead)

---

### Parallel Test Execution (Terraform 1.12+)

```bash
# Run test files in parallel (default: 10)
terraform test -parallelism=4

# Sequential (for tests with shared state or external dependencies)
terraform test -parallelism=1
```

> **Note**: Parallelism applies across test **files**, not within a single file. Run blocks within one `.tftest.hcl` always execute sequentially.

---

### File-Level Variable Definitions (Terraform 1.13+)

Define `variable` blocks directly in `.tftest.hcl` files. These are scoped to the test file and can reference run outputs:

```hcl
# File-level variable (scoped to this test file)
variable "test_environment" {
  type    = string
  default = "staging"
}

# Use in global variables block
variables {
  environment = var.test_environment   # Reference file-level variable
}

# Use in run blocks
run "example" {
  variables {
    environment = var.test_environment
  }
}
```

**See**: [tests/advanced-features.tftest.hcl](example/tests/advanced-features.tftest.hcl) for working examples of all these features.

---

## CI/CD Integration

For full CI/CD integration examples (GitHub Actions, Azure DevOps, JUnit XML samples), see:

**[tests/ci-integration.md](example/tests/ci-integration.md)**

Quick reference:

```bash
# Standard run
terraform test

# CI/CD with JUnit XML (1.11+)
terraform test -junit-xml=results.xml

# Parallel execution (1.12+)
terraform test -parallelism=4

# Filter to specific file
terraform test -filter=tests/basic.tftest.hcl

# Full CI command
terraform test -parallelism=4 -junit-xml=results.xml -verbose
```

---

## Additional Resources

### Official Documentation
- [Terraform Test Framework](https://developer.hashicorp.com/terraform/language/tests)
- [Mock Providers](https://developer.hashicorp.com/terraform/language/tests/mocking)
- [Libvirt Provider](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs)

### Testing Strategies
- [Test-Driven Infrastructure](https://www.hashicorp.com/blog/testing-hashicorp-terraform)
- [Testing Terraform Modules](https://www.terraform.io/docs/language/modules/testing-experiment.html)

### Next Steps
- **TF-304**: Policy as Code (OPA/Rego)
- **PKR-100**: Packer Fundamentals
- **Cloud Modules**: Apply testing to AWS/Azure

---

## Summary

In this course, you learned:

✅ **Test Framework Basics**: Writing `.tftest.hcl` files with run blocks and assertions
✅ **Plan vs Apply**: Choosing the right command for unit vs integration tests
✅ **Mock Providers**: Testing configuration logic without infrastructure
✅ **Test Organization**: Structuring tests for maintainability
✅ **Best Practices**: Writing clear, independent, comprehensive tests
✅ **Debugging**: Strategies for troubleshooting failed tests
✅ **JUnit XML Output** (1.11+): CI/CD integration with `-junit-xml`
✅ **`override_during = plan`** (1.11+): True unit testing with zero provider interaction
✅ **`state_key`** (1.11+): Shared state between run blocks for multi-step scenarios
✅ **Parallel Execution** (1.12+): `-parallelism` flag for faster test suites
✅ **File-Level Variables** (1.13+): `variable` blocks scoped to test files

### Key Takeaways

1. **Test Early, Test Often**: Write tests as you develop infrastructure code
2. **Use Mocks for Speed**: Unit tests with mocks provide fast feedback
3. **Integration Tests for Confidence**: Real infrastructure tests catch integration issues
4. **Clear Messages**: Good error messages save debugging time
5. **Independent Tests**: Each test should be self-contained

### What's Next?

Continue to **TF-304: Policy as Code** to learn how to enforce organizational standards and compliance requirements using OPA/Rego and Sentinel.

---

**Course**: TF-300 Advanced Terraform  
**Module**: TF-303 - Terraform Test Framework  
**Duration**: 1 hour  
**Last Updated**: 2026-03-01