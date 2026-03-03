# TF-204: Import & Migration Strategies

**Course Level**: 200 (Intermediate)  
**Duration**: 1.5 hours  
**Prerequisites**: TF-201 (Module Design & Composition)

---

## 📋 Overview

This course teaches you how to import existing infrastructure into Terraform management and migrate legacy code to modern patterns. You'll learn import blocks (Terraform 1.5+), the terraform import CLI, state manipulation techniques, moved blocks for refactoring, and strategies for migrating from manual management to Infrastructure as Code.

**Why Import & Migration Matter**: Most organizations have existing infrastructure that wasn't created with Terraform. Learning to import and migrate this infrastructure is essential for adopting IaC without starting from scratch.

---

## 🎯 Learning Objectives

By the end of this course, you will be able to:

- ✅ Import existing resources using import blocks (Terraform 1.5+)
- ✅ Use terraform import CLI for legacy workflows
- ✅ Generate Terraform configuration from existing resources
- ✅ Manipulate state safely for migrations
- ✅ Use moved blocks for refactoring
- ✅ Migrate legacy code to modern patterns
- ✅ Handle import errors and edge cases
- ✅ Plan and execute large-scale migrations
- ✅ Validate imported resources
- ✅ Document migration processes

---

## 📚 Course Structure

This course covers import and migration strategies in a comprehensive single section with multiple examples and labs.

### Key Topics Covered

**Import Strategies**:
- Import blocks (Terraform 1.5+)
- terraform import CLI
- Configuration generation
- Bulk import techniques

**State Management**:
- State manipulation commands
- State mv for renaming
- State rm for removal
- State backup and recovery

**Refactoring**:
- Moved blocks
- Resource renaming
- Module extraction
- Code reorganization

**Migration Planning**:
- Assessment strategies
- Phased migration approach
- Validation techniques
- Rollback procedures

---

## 💻 Hands-On Lab 1: Import with Import Blocks

### Objective
Import existing Libvirt resources using modern import blocks (Terraform 1.5+).

### Duration
20 minutes

### Scenario
You have manually created Libvirt networks and VMs. Now you want to manage them with Terraform.

### Step 1: Discover Existing Resources

```bash
# List existing networks
virsh net-list --all

# List existing VMs
virsh list --all

# Get network details
virsh net-dumpxml <network-name>

# Get VM details
virsh dumpxml <vm-name>
```

### Step 2: Create Import Configuration

```hcl
# main.tf
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

# Import block for existing network
import {
  to = libvirt_network.existing_network
  id = "existing-network"  # Network name
}

# Resource configuration (will be populated)
resource "libvirt_network" "existing_network" {
  name      = "existing-network"
  mode      = "nat"
  addresses = ["10.17.3.0/24"]
  autostart = true
  
  dns {
    enabled = true
  }
  
  dhcp {
    enabled = true
  }
}

# Import block for existing VM
import {
  to = libvirt_domain.existing_vm
  id = "existing-vm"  # VM name
}

# Resource configuration
resource "libvirt_domain" "existing_vm" {
  name   = "existing-vm"
  memory = 1024
  vcpu   = 2
  
  # Network interface (will be discovered)
  network_interface {
    network_name = "existing-network"
  }
  
  # Disk (will be discovered)
  disk {
    volume_id = "/var/lib/libvirt/images/existing-vm.qcow2"
  }
}
```

### Step 3: Generate Configuration

```bash
# Generate configuration from existing resources
terraform plan -generate-config-out=generated.tf

# This creates generated.tf with actual resource configuration
```

### Step 4: Review Generated Configuration

```hcl
# generated.tf (example output)
resource "libvirt_network" "existing_network" {
  addresses = ["10.17.3.0/24"]
  autostart = true
  bridge    = "virbr1"
  dhcp {
    enabled = true
  }
  dns {
    enabled    = true
    local_only = false
  }
  mode = "nat"
  name = "existing-network"
}

resource "libvirt_domain" "existing_vm" {
  arch      = "x86_64"
  autostart = false
  disk {
    scsi      = false
    volume_id = "/var/lib/libvirt/images/existing-vm.qcow2"
  }
  machine = "pc-q35-7.2"
  memory  = 1024
  name    = "existing-vm"
  network_interface {
    addresses      = ["10.17.3.100"]
    hostname       = "existing-vm"
    network_name   = "existing-network"
    wait_for_lease = false
  }
  vcpu = 2
}
```

### Step 5: Import Resources

```bash
# Plan to see what will be imported
terraform plan

# Apply to import into state
terraform apply

# Verify import
terraform state list
terraform state show libvirt_network.existing_network
```

### Key Takeaways

- ✅ Import blocks are declarative and version-controlled
- ✅ Configuration generation saves time
- ✅ Always review generated config before applying
- ✅ Import is idempotent (safe to re-run)
- ✅ Import blocks can stay in code as documentation

---

## 💻 Hands-On Lab 2: Legacy Import with CLI

### Objective
Use the terraform import CLI command for legacy workflows.

### Duration
15 minutes

### When to Use CLI Import

- Terraform < 1.5
- Quick one-off imports
- Scripting bulk imports
- CI/CD pipelines (legacy)

### Import Workflow

#### 1. Create Resource Configuration

```hcl
# main.tf
resource "libvirt_network" "imported" {
  name      = "legacy-network"
  mode      = "nat"
  addresses = ["10.20.0.0/24"]
}
```

#### 2. Import Using CLI

```bash
# Import network
terraform import libvirt_network.imported legacy-network

# Import VM
terraform import libvirt_domain.imported legacy-vm

# Import storage pool
terraform import libvirt_pool.imported legacy-pool
```

#### 3. Verify and Adjust

```bash
# Check state
terraform state show libvirt_network.imported

# Plan to see differences
terraform plan

# Adjust configuration to match actual resource
```

### Bulk Import Script

```bash
#!/bin/bash
# import-networks.sh

# List of networks to import
networks=("web-network" "app-network" "db-network")

for net in "${networks[@]}"; do
  echo "Importing network: $net"
  terraform import "libvirt_network.networks[\"$net\"]" "$net"
done
```

### Key Takeaways

- ✅ CLI import requires pre-existing resource configuration
- ✅ Import ID format varies by resource type
- ✅ Always verify with terraform plan after import
- ✅ Use scripts for bulk imports
- ✅ Prefer import blocks for new projects

---

## 💻 Hands-On Lab 3: State Manipulation & Refactoring

### Objective
Use state manipulation commands and moved blocks for refactoring.

### Duration
25 minutes

### Scenario 1: Rename Resource

```hcl
# Before: Poor naming
resource "libvirt_network" "net1" {
  name = "production-network"
}

# After: Better naming
resource "libvirt_network" "production" {
  name = "production-network"
}

# Use moved block to prevent destruction
moved {
  from = libvirt_network.net1
  to   = libvirt_network.production
}
```

### Scenario 2: Extract to Module

```hcl
# Before: Flat configuration
resource "libvirt_network" "web" {
  name = "web-network"
}

resource "libvirt_domain" "web" {
  name = "web-vm"
}

# After: Module extraction
module "web_tier" {
  source = "./modules/tier"
  
  tier_name = "web"
}

# Use moved blocks
moved {
  from = libvirt_network.web
  to   = module.web_tier.libvirt_network.this
}

moved {
  from = libvirt_domain.web
  to   = module.web_tier.libvirt_domain.this
}
```

### Scenario 3: State Commands

```bash
# List all resources
terraform state list

# Show resource details
terraform state show libvirt_network.production

# Move resource in state (rename)
terraform state mv libvirt_network.old libvirt_network.new

# Remove resource from state (manual management)
terraform state rm libvirt_network.temp

# Pull state to file
terraform state pull > terraform.tfstate.backup

# Push state from file (dangerous!)
terraform state push terraform.tfstate.backup
```

### Scenario 4: Convert Count to For_Each

```hcl
# Before: Using count
resource "libvirt_domain" "vms" {
  count = 3
  name  = "vm-${count.index}"
}

# After: Using for_each
resource "libvirt_domain" "vms" {
  for_each = toset(["web-01", "web-02", "web-03"])
  name     = each.key
}

# Migration steps:
# 1. Add new for_each resources
# 2. Import existing VMs to new addresses
# 3. Remove old count resources from state
# 4. Clean up configuration
```

### Key Takeaways

- ✅ Moved blocks prevent resource destruction during refactoring
- ✅ State commands enable manual state manipulation
- ✅ Always backup state before manipulation
- ✅ Test refactoring in non-production first
- ✅ Use terraform plan to verify changes

---

## 📝 Checkpoint Quiz

### Question 1: Import Blocks vs CLI
**What is the PRIMARY advantage of import blocks over terraform import CLI?**

A) Faster execution  
B) Works with older Terraform versions  
C) Declarative and version-controlled  
D) Requires less configuration

<details>
<summary>Show Answer</summary>

**Answer: C** - Declarative and version-controlled

**Explanation**: Import blocks (Terraform 1.5+) provide:
- **Declarative**: Defined in configuration files
- **Version-controlled**: Part of your Git repository
- **Reproducible**: Same import process every time
- **CI/CD friendly**: Works in automated pipelines
- **Preview**: Can see import plan before applying
- **Documentation**: Shows resource origin

CLI import is imperative and not tracked in version control.
</details>

---

### Question 2: Configuration Generation
**What command generates Terraform configuration from existing resources?**

A) terraform generate  
B) terraform plan -generate-config-out=file.tf  
C) terraform import -generate  
D) terraform show -generate

<details>
<summary>Show Answer</summary>

**Answer: B** - terraform plan -generate-config-out=file.tf

**Explanation**: 
```bash
# Generate configuration during plan
terraform plan -generate-config-out=generated.tf
```

This creates a file with Terraform configuration matching the actual resource state. Useful for:
- Importing complex resources
- Bulk imports
- Learning resource syntax
- Migrating from manual management

Always review generated config before using it!
</details>

---

### Question 3: Moved Blocks
**What is the purpose of moved blocks?**

A) To move resources between providers  
B) To prevent resource destruction during refactoring  
C) To move state files  
D) To migrate between Terraform versions

<details>
<summary>Show Answer</summary>

**Answer: B** - To prevent resource destruction during refactoring

**Explanation**: Moved blocks tell Terraform that a resource has been renamed or moved in configuration:

```hcl
moved {
  from = libvirt_network.old_name
  to   = libvirt_network.new_name
}
```

Without moved blocks, Terraform would:
1. Destroy resource at old address
2. Create resource at new address

With moved blocks, Terraform:
1. Updates state to new address
2. No infrastructure changes

Essential for safe refactoring!
</details>

---

### Question 4: State Manipulation
**Which command removes a resource from Terraform state without destroying it?**

A) terraform destroy -target=resource  
B) terraform state rm resource  
C) terraform delete resource  
D) terraform remove resource

<details>
<summary>Show Answer</summary>

**Answer: B** - terraform state rm resource

**Explanation**:
```bash
# Remove from state (resource continues to exist)
terraform state rm libvirt_network.temp

# Destroy resource (removes from state AND infrastructure)
terraform destroy -target=libvirt_network.temp
```

Use cases for `state rm`:
- Transitioning to manual management
- Moving resources to different state files
- Removing resources that no longer exist
- Fixing state corruption

Always backup state first!
</details>

---

### Question 5: Import ID Format
**How do you find the correct import ID for a resource?**

A) Guess based on resource name  
B) Check provider documentation  
C) Use terraform show  
D) It's always the resource name

<details>
<summary>Show Answer</summary>

**Answer: B** - Check provider documentation

**Explanation**: Import ID format varies by provider and resource type:

**Libvirt**:
- Network: Network name (`"my-network"`)
- Domain: Domain name (`"my-vm"`)
- Pool: Pool name (`"my-pool"`)

**AWS**:
- VPC: VPC ID (`"vpc-12345678"`)
- EC2: Instance ID (`"i-12345678"`)

**Azure**:
- Resource Group: Full ARM ID (`"/subscriptions/.../resourceGroups/my-rg"`)

Always check provider docs for correct format!
</details>

---

### Question 6: Migration Strategy
**What is the recommended approach for large-scale migrations?**

A) Import everything at once  
B) Phased migration with validation  
C) Recreate all infrastructure  
D) Use manual state editing

<details>
<summary>Show Answer</summary>

**Answer: B** - Phased migration with validation

**Explanation**: Best practice migration approach:

**Phase 1: Assessment**
- Inventory existing resources
- Identify dependencies
- Plan migration order

**Phase 2: Pilot**
- Import non-critical resources first
- Validate and test
- Refine process

**Phase 3: Incremental Migration**
- Import in logical groups
- Validate after each group
- Monitor for issues

**Phase 4: Validation**
- Compare state to actual infrastructure
- Test terraform plan (should show no changes)
- Document any discrepancies

**Phase 5: Cleanup**
- Remove temporary resources
- Optimize configuration
- Update documentation

Never import everything at once - too risky!
</details>

---

## 📖 Migration Strategies

### Strategy 1: Phased Migration

```
Phase 1: Networks (Foundation)
├── Import all networks
├── Validate connectivity
└── Test terraform plan

Phase 2: Storage (Dependencies)
├── Import storage pools
├── Import volumes
└── Validate references

Phase 3: Compute (Applications)
├── Import VMs
├── Validate configurations
└── Test full stack

Phase 4: Validation & Cleanup
├── Compare state to reality
├── Fix discrepancies
└── Document changes
```

### Strategy 2: Parallel Management

```
Week 1-2: Setup
├── Create Terraform configurations
├── Import non-critical resources
└── Validate in parallel with manual management

Week 3-4: Transition
├── Import critical resources
├── Test changes in Terraform
└── Maintain manual backup

Week 5-6: Full Adoption
├── All changes through Terraform
├── Decommission manual processes
└── Monitor and optimize
```

### Strategy 3: Greenfield Migration

```
Option 1: Recreate
├── Build new infrastructure with Terraform
├── Migrate applications
├── Decommission old infrastructure
└── Clean cutover

Option 2: Blue-Green
├── Build parallel environment with Terraform
├── Test thoroughly
├── Switch traffic
└── Keep old environment as backup
```

---

## 🔧 Advanced Techniques

### Technique 1: Bulk Import with For_Each

```hcl
# Define resources to import
locals {
  networks_to_import = {
    "web-network" = {
      mode      = "nat"
      addresses = ["10.10.0.0/24"]
    }
    "app-network" = {
      mode      = "nat"
      addresses = ["10.20.0.0/24"]
    }
    "db-network" = {
      mode      = "nat"
      addresses = ["10.30.0.0/24"]
    }
  }
}

# Import blocks with for_each
import {
  for_each = local.networks_to_import
  to       = libvirt_network.networks[each.key]
  id       = each.key
}

# Resource configuration
resource "libvirt_network" "networks" {
  for_each = local.networks_to_import
  
  name      = each.key
  mode      = each.value.mode
  addresses = each.value.addresses
  autostart = true
  
  dns {
    enabled = true
  }
  
  dhcp {
    enabled = true
  }
}
```

### Technique 2: Import with Data Sources

```hcl
# Discover existing resources
data "external" "existing_networks" {
  program = ["bash", "-c", "virsh net-list --name | jq -R -s -c 'split(\"\n\")[:-1]'"]
}

locals {
  network_names = jsondecode(data.external.existing_networks.result)
}

# Import discovered resources
import {
  for_each = toset(local.network_names)
  to       = libvirt_network.discovered[each.key]
  id       = each.value
}
```

### Technique 3: Validation After Import

```hcl
# Check that imported resources match configuration
check "import_validation" {
  data "libvirt_network" "verify" {
    for_each = libvirt_network.networks
    name     = each.value.name
  }
  
  assert {
    condition = alltrue([
      for name, net in data.libvirt_network.verify :
      net.addresses[0] == libvirt_network.networks[name].addresses[0]
    ])
    error_message = "Imported network configuration mismatch"
  }
}
```

---

## 🎓 Best Practices

### 1. Always Backup State

```bash
# Before any state manipulation
terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate

# Verify backup
ls -lh backup-*.tfstate
```

### 2. Use Import Blocks (Terraform 1.5+)

```hcl
# ✅ GOOD: Declarative, version-controlled
import {
  to = libvirt_network.production
  id = "prod-network"
}

# ❌ AVOID: Imperative, not tracked
# terraform import libvirt_network.production prod-network
```

### 3. Validate After Import

```bash
# Import resources
terraform apply

# Verify no changes needed
terraform plan

# Should show: "No changes. Your infrastructure matches the configuration."
```

### 4. Document Import Process

```markdown
# Import Log

## Date: 2024-01-15
## Resources Imported:
- libvirt_network.web (web-network)
- libvirt_network.app (app-network)
- libvirt_domain.web-01 (web-01)

## Issues Encountered:
- Network CIDR mismatch (fixed in config)
- VM memory setting different (updated config)

## Validation:
- terraform plan shows no changes ✓
- All resources accessible ✓
```

### 5. Test in Non-Production First

```
1. Import in dev environment
2. Validate and refine process
3. Document lessons learned
4. Apply to staging
5. Finally, production
```

---

## 📚 Additional Resources

### Official Documentation
- [Import Blocks](https://developer.hashicorp.com/terraform/language/import)
- [terraform import CLI](https://developer.hashicorp.com/terraform/cli/commands/import)
- [State Commands](https://developer.hashicorp.com/terraform/cli/commands/state)
- [Moved Blocks](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring)

### Migration Guides
- [Migrating to Terraform](https://developer.hashicorp.com/terraform/tutorials/state/state-import)
- [Refactoring](https://developer.hashicorp.com/terraform/tutorials/configuration-language/move-config)

### Tools
- [Terraformer](https://github.com/GoogleCloudPlatform/terraformer) - Generate Terraform from existing infrastructure
- [Terracognita](https://github.com/cycloidio/terracognita) - Import infrastructure to Terraform

---

## 📦 Supplemental Content

Extend your TF-204 knowledge with these additional topics:

| Section | Topic | Description |
|---------|-------|-------------|
| [removed-blocks/](removed-blocks/README.md) | `removed` Blocks (Terraform 1.7+) | Declaratively remove resources from state without destroying them |
| [identity-import/](identity-import/README.md) | Identity-Based Import (Terraform 1.12+) | Import using structured identity attributes instead of string IDs |

---

## 🎉 Congratulations!

You've completed TF-204: Import & Migration Strategies!

### What You've Learned

- ✅ Import blocks (Terraform 1.5+)
- ✅ terraform import CLI
- ✅ Configuration generation
- ✅ State manipulation commands
- ✅ Moved blocks for refactoring
- ✅ Migration planning strategies
- ✅ Bulk import techniques
- ✅ Validation approaches
- ✅ Best practices for safe migrations
- ✅ `removed` blocks for declarative state removal *(Supplemental)*
- ✅ Identity-based import blocks (Terraform 1.12+) *(Supplemental)*

### Phase 2 Complete!

You've finished the entire **TF-200: Modules & Patterns** series:
- ✅ TF-201: Module Design & Composition
- ✅ TF-202: Advanced Module Patterns
- ✅ TF-203: YAML-Driven Configuration
- ✅ TF-204: Import & Migration Strategies

### Next Steps

**Continue to TF-300**: Testing, Validation & Policy
- TF-301: Input Validation & Advanced Functions
- TF-302: Pre/Post Conditions & Check Blocks
- TF-303: Terraform Test Framework
- TF-304: Policy as Code (OPA/Rego)

**Or PKR-100**: Packer Fundamentals
- Learn to build machine images
- Integrate with Terraform
- Automate image creation

---

**Ready to master testing and validation?** Continue to TF-300! 🚀

---

*This course demonstrates import and migration strategies applicable to all Terraform providers. The concepts of importing, state management, and refactoring are provider-agnostic.*