# TF-202: Advanced Module Patterns

**Course Level**: 200 (Intermediate)  
**Duration**: 1.5 hours  
**Prerequisites**: TF-201 (Module Design & Composition)

---

## 📋 Overview

This course covers advanced module patterns including nested modules, conditional resource creation, for_each patterns, module testing, canary deployments, and private module registries. You'll learn enterprise-grade module management practices that scale.

**Why Advanced Patterns Matter**: Simple modules work for small projects, but enterprise infrastructure needs patterns that scale, adapt, and enable safe deployments across complex environments.

---

## 🎯 Learning Objectives

By the end of this course, you will be able to:

- ✅ Create nested module hierarchies for complex infrastructure
- ✅ Implement conditional resource creation in modules
- ✅ Use for_each patterns effectively for multiple resources
- ✅ Build reusable module libraries
- ✅ Test modules systematically
- ✅ Implement canary deployment patterns
- ✅ Host modules in private registries
- ✅ Version modules using semantic versioning
- ✅ Apply advanced composition patterns
- ✅ Implement safe deployment strategies with rollback

---

## 📚 Course Structure

This course is organized into **2 comprehensive sections**:

### 1. Private Module Registry 📦
**Directory**: [`1-private-registry/`](./1-private-registry/)  
**Duration**: 30 minutes

**Topics Covered**:
- Why use private module registries
- Terraform Cloud module registry
- Git-based module sources
- Module versioning strategies
- Semantic versioning (MAJOR.MINOR.PATCH)
- Module documentation standards
- Access control and security
- Module discovery and sharing

**Key Concepts**:
- **Security**: Control access to proprietary modules
- **Collaboration**: Share modules across teams
- **Quality**: Version control and testing
- **Discovery**: Centralized module catalog

---

### 2. Canary Deployments & Advanced Patterns 🚀
**Directory**: [`2-canary-deployments/`](./2-canary-deployments/)  
**Duration**: 60 minutes

**Topics Covered**:
- Canary deployment patterns
- Blue-green deployment strategies
- Nested module composition
- Conditional resource creation
- For_each patterns in modules
- Module testing strategies
- Health checks and validation
- Rollback procedures
- Feature flags
- Environment-based configuration

**Key Patterns**:
- **Canary**: Gradual rollout to subset (10% → 50% → 100%)
- **Blue-Green**: Two identical environments, instant switch
- **Nested Modules**: Hierarchical composition (network → compute → app)
- **Conditional**: Resources created based on variables
- **For_Each**: Multiple similar resources with stable addresses

---

## 🚀 Recommended Learning Path

1. **Start with Private Registry** (1-private-registry/)
   - Understand module hosting options
   - Learn versioning strategies
   - Explore module sources (local, Git, registry)

2. **Master Advanced Patterns** (2-canary-deployments/)
   - Implement canary deployments
   - Practice conditional resources
   - Build nested modules
   - Use for_each patterns
   - Test your modules

---

## 💻 Hands-On Labs

### Lab 1: Nested Module Hierarchy
**Duration**: 25 minutes  
**Difficulty**: Intermediate

**Objective**: Create a 3-layer nested module structure.

**Structure**:
```
modules/
├── app-stack/       # Top layer (uses all below)
├── network/         # Network layer
├── storage/         # Storage layer
└── compute/         # Compute layer
```

**What You'll Build**:
- Network module (creates libvirt networks)
- Storage module (creates pools and volumes)
- Compute module (creates VMs)
- App-stack module (composes all three)

**Key Learning**:
- Module composition through outputs/inputs
- Clear separation of concerns
- Reusable components at each layer
- Simple top-level interface

---

### Lab 2: Conditional Resources with For_Each
**Duration**: 20 minutes  
**Difficulty**: Intermediate

**Objective**: Create a module that conditionally creates resources and uses for_each for multiple instances.

**Features**:
- Conditional network creation (create new or use existing)
- Multiple VMs using for_each with map
- Environment-based autostart (production only)
- Conditional monitoring setup

**Example Usage**:
```hcl
module "app_cluster" {
  source = "./modules/conditional-vm"
  
  environment    = "production"
  create_network = true
  
  vms = {
    web-01 = { memory_mb = 2048, vcpu_count = 2 }
    web-02 = { memory_mb = 2048, vcpu_count = 2 }
    app-01 = { memory_mb = 4096, vcpu_count = 4 }
  }
}
```

**Key Learning**:
- Use `count` for conditional single resources
- Use `for_each` for multiple similar resources
- Combine conditionals with for_each
- Environment-based resource creation

---

### Lab 3: Canary Deployment Pattern
**Duration**: 30 minutes  
**Difficulty**: Advanced

**Objective**: Implement a canary deployment pattern with gradual rollout.

**Deployment Phases**:
1. **Phase 1**: 100% stable, 0% canary
2. **Phase 2**: 90% stable, 10% canary (monitor)
3. **Phase 3**: 50% stable, 50% canary (monitor)
4. **Phase 4**: 0% stable, 100% new version

**Features**:
- Automatic instance count calculation
- Health checks for both versions
- Easy rollback (adjust percentage)
- Version tracking

**Example Usage**:
```hcl
module "app" {
  source = "./modules/canary-deployment"
  
  app_name          = "my-app"
  total_instances   = 5
  enable_canary     = true
  canary_percentage = 10  # Start with 10%
  
  stable_version    = "v1.0.0"
  canary_version    = "v1.1.0"
  stable_image_path = "/path/to/v1.0.0.qcow2"
  canary_image_path = "/path/to/v1.1.0.qcow2"
}

# Output: 4 stable instances, 1 canary instance
```

**Key Learning**:
- Gradual rollout reduces risk
- Health checks enable automated validation
- Easy rollback by adjusting percentage
- Clear separation of stable/canary versions

---

## 📝 Checkpoint Quiz

### Question 1: Nested Modules
**What is the PRIMARY benefit of nested module hierarchies?**

A) Faster Terraform execution  
B) Smaller state files  
C) Clear separation of concerns and reusability  
D) Automatic error handling

<details>
<summary>Show Answer</summary>

**Answer: C** - Clear separation of concerns and reusability

**Explanation**: Nested modules provide:
- Clear architectural layers (network, compute, storage)
- Reusable components at each level
- Single responsibility per module
- Easier testing and maintenance
- Simplified top-level interface
</details>

---

### Question 2: Conditional Resources
**Which meta-argument is best for conditionally creating a SINGLE resource?**

A) for_each  
B) count  
C) depends_on  
D) lifecycle

<details>
<summary>Show Answer</summary>

**Answer: B** - count

**Explanation**: Use `count` for conditional single resources:
```hcl
resource "libvirt_network" "this" {
  count = var.create_network ? 1 : 0
  # ...
}
```

Use `for_each` for multiple similar resources with stable addresses.
</details>

---

### Question 3: For_Each vs Count
**What is the advantage of for_each over count for multiple resources?**

A) Faster execution  
B) Stable resource addresses when items change  
C) Smaller state files  
D) Automatic validation

<details>
<summary>Show Answer</summary>

**Answer: B** - Stable resource addresses when items change

**Explanation**: 

**With count** (index-based):
- Resources: vm[0], vm[1], vm[2]
- Removing vm[1] shifts vm[2] to vm[1] (destructive!)

**With for_each** (key-based):
- Resources: vm["web-01"], vm["web-02"], vm["db-01"]
- Removing web-02 doesn't affect others

for_each provides stable addresses based on keys, not indices.
</details>

---

### Question 4: Canary Deployment
**What is the correct order for a canary deployment?**

A) Deploy 100% → Monitor → Rollback if needed  
B) Deploy small % → Monitor → Gradually increase → Full rollout  
C) Deploy 50% → Monitor → Deploy remaining 50%  
D) Deploy all → Test → Rollback if needed

<details>
<summary>Show Answer</summary>

**Answer: B** - Deploy small % → Monitor → Gradually increase → Full rollout

**Explanation**: Canary deployment phases:
1. Deploy canary (10% of instances)
2. Monitor metrics (errors, performance)
3. Gradually increase (20%, 50%, 75%)
4. Full rollout (100%) when validated
5. Rollback at any point if issues detected

This minimizes risk by limiting exposure to new version.
</details>

---

### Question 5: Module Versioning
**What does the version constraint `~> 1.2` mean?**

A) Exactly version 1.2.0  
B) Any version >= 1.2.0  
C) Versions 1.2.x (not 1.3.0)  
D) Versions between 1.2.0 and 2.0.0

<details>
<summary>Show Answer</summary>

**Answer: C** - Versions 1.2.x (not 1.3.0)

**Explanation**: The pessimistic constraint `~>` allows:
- `~> 1.2` → Allows 1.2.0, 1.2.1, 1.2.99, but NOT 1.3.0
- `~> 1.2.0` → Allows 1.2.0, 1.2.1, but NOT 1.3.0

Useful for accepting patch updates while preventing minor version changes.
</details>

---

### Question 6: Health Checks
**Why are health checks important in canary deployments?**

A) They make deployments faster  
B) They enable automated validation and rollback  
C) They are required by Terraform  
D) They reduce infrastructure costs

<details>
<summary>Show Answer</summary>

**Answer: B** - They enable automated validation and rollback

**Explanation**: Health checks provide:
- Automated validation of new version
- Early detection of issues
- Automated rollback triggers
- Confidence in deployment process
- Reduced manual intervention

Example:
```hcl
check "canary_health" {
  assert {
    condition     = data.http.health_check.status_code == 200
    error_message = "Canary failed - consider rollback"
  }
}
```
</details>

---

## 📖 Key Concepts Reference

### Nested Module Pattern

```hcl
# Top-level module
module "app_stack" {
  source = "./modules/app-stack"
  
  # Simple interface
  app_name = "my-app"
  environment = "production"
}

# Internally uses:
# - module "network" (creates networks)
# - module "storage" (creates storage)
# - module "compute" (creates VMs)
```

**Benefits**:
- Clear separation of concerns
- Reusable components
- Simple top-level interface
- Easy to test each layer

---

### Conditional Resource Pattern

```hcl
# Single resource conditional
resource "libvirt_network" "this" {
  count = var.create_network ? 1 : 0
  # ...
}

# Multiple resources conditional
resource "libvirt_domain" "canary" {
  count = var.enable_canary ? var.canary_count : 0
  # ...
}

# Environment-based conditional
resource "null_resource" "monitoring" {
  count = var.environment == "production" ? 1 : 0
  # ...
}
```

---

### For_Each Pattern

```hcl
# Map-based for_each
variable "vms" {
  type = map(object({
    memory_mb  = number
    vcpu_count = number
  }))
}

resource "libvirt_domain" "vm" {
  for_each = var.vms
  
  name   = each.key
  memory = each.value.memory_mb
  vcpu   = each.value.vcpu_count
}

# Usage
vms = {
  web-01 = { memory_mb = 2048, vcpu_count = 2 }
  web-02 = { memory_mb = 2048, vcpu_count = 2 }
  app-01 = { memory_mb = 4096, vcpu_count = 4 }
}
```

---

### Canary Deployment Pattern

```hcl
locals {
  stable_count = var.enable_canary ? 
    floor(var.total_instances * (1 - var.canary_percentage / 100)) : 
    var.total_instances
  
  canary_count = var.enable_canary ? 
    ceil(var.total_instances * (var.canary_percentage / 100)) : 
    0
}

# Stable version instances
resource "libvirt_domain" "stable" {
  count = local.stable_count
  # ...
}

# Canary version instances
resource "libvirt_domain" "canary" {
  count = local.canary_count
  # ...
}
```

**Deployment Flow**:
1. Start: 100% stable (canary_percentage = 0)
2. Phase 1: 90% stable, 10% canary (canary_percentage = 10)
3. Phase 2: 50% stable, 50% canary (canary_percentage = 50)
4. Complete: 100% new version (disable canary, update stable)

---

### Module Versioning

**Semantic Versioning**:
```
MAJOR.MINOR.PATCH

1.0.0 → 1.0.1  # Patch: Bug fixes
1.0.1 → 1.1.0  # Minor: New features (backward compatible)
1.1.0 → 2.0.0  # Major: Breaking changes
```

**Version Constraints**:
```hcl
# Exact version
version = "1.2.3"

# Minimum version
version = ">= 1.2.0"

# Version range
version = ">= 1.2.0, < 2.0.0"

# Pessimistic constraint (recommended)
version = "~> 1.2"  # Allows 1.2.x, not 1.3.0
```

---

### Module Sources

**Local Path**:
```hcl
module "network" {
  source = "./modules/network"
}
```

**Git Repository**:
```hcl
module "network" {
  source = "git::https://github.com/org/modules.git//network?ref=v1.0.0"
}
```

**Terraform Registry**:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
}
```

**Terraform Cloud**:
```hcl
module "network" {
  source  = "app.terraform.io/myorg/network/libvirt"
  version = "1.2.0"
}
```

---

## 🔧 Advanced Patterns

### Pattern 1: Feature Flags

```hcl
variable "features" {
  type = object({
    monitoring = bool
    backup     = bool
    logging    = bool
  })
  default = {
    monitoring = false
    backup     = false
    logging    = false
  }
}

resource "null_resource" "monitoring" {
  count = var.features.monitoring ? 1 : 0
  # Setup monitoring
}
```

### Pattern 2: Environment-Based Configuration

```hcl
locals {
  env_config = {
    dev = {
      instance_count = 1
      memory_mb      = 512
      enable_backup  = false
    }
    production = {
      instance_count = 5
      memory_mb      = 4096
      enable_backup  = true
    }
  }
  
  config = local.env_config[var.environment]
}

resource "libvirt_domain" "vm" {
  count  = local.config.instance_count
  memory = local.config.memory_mb
  # ...
}
```

### Pattern 3: Module Testing

```hcl
# tests/network_test.tftest.hcl
run "create_network" {
  command = apply
  
  variables {
    network_name = "test-network"
    addresses    = ["10.99.0.0/24"]
  }
  
  assert {
    condition     = libvirt_network.this.name == "test-network"
    error_message = "Network name mismatch"
  }
}

run "cleanup" {
  command = destroy
}
```

---

## 🎓 Best Practices

### Module Development

1. **Keep modules focused** - Single responsibility
2. **Document thoroughly** - README, variables, outputs
3. **Test extensively** - Validate before publishing
4. **Version properly** - Use semantic versioning
5. **Provide examples** - Show usage patterns

### Deployment Strategy

1. **Start small** - Begin with 10% canary
2. **Monitor closely** - Watch metrics during rollout
3. **Automate rollback** - Define clear criteria
4. **Communicate** - Inform team of deployments
5. **Document incidents** - Learn from issues

### Security

1. **Validate inputs** - Use validation blocks
2. **Protect secrets** - Use sensitive = true
3. **Least privilege** - Minimal permissions
4. **Access control** - Restrict module access
5. **Audit logging** - Track module usage

---

## 📚 Additional Resources

### Official Documentation
- [Terraform Modules](https://developer.hashicorp.com/terraform/language/modules)
- [Module Development](https://developer.hashicorp.com/terraform/language/modules/develop)
- [Terraform Cloud Registry](https://developer.hashicorp.com/terraform/cloud-docs/registry)
- [Module Testing](https://developer.hashicorp.com/terraform/language/tests)

### Deployment Patterns
- [Canary Deployments](https://martinfowler.com/bliki/CanaryRelease.html)
- [Blue-Green Deployments](https://martinfowler.com/bliki/BlueGreenDeployment.html)

### Community Resources
- [Terraform Registry](https://registry.terraform.io/) - Public modules
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

## 🎉 Congratulations!

You've completed TF-202: Advanced Module Patterns!

### What You've Learned

- ✅ Nested module hierarchies
- ✅ Conditional resource creation
- ✅ For_each patterns for multiple resources
- ✅ Canary deployment strategies
- ✅ Module versioning and registries
- ✅ Module testing approaches
- ✅ Advanced composition patterns
- ✅ Safe deployment practices

### Next Steps

**Continue to TF-203**: YAML-Driven Configuration
- Drive infrastructure from YAML files
- Dynamic resource creation
- Configuration as data
- Template-based infrastructure

**Or TF-204**: Import & Migration Strategies
- Import existing infrastructure
- Migrate legacy code
- State manipulation techniques
- Refactoring strategies

---

**Ready to master YAML-driven infrastructure?** Continue to TF-203! 🚀

---

*This course uses advanced patterns applicable to all Terraform providers. The concepts of nested modules, conditionals, for_each, and deployment patterns are provider-agnostic.*
