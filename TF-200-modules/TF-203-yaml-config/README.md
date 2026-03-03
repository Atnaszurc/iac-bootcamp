# TF-203: YAML-Driven Configuration

**Course Level**: 200 (Intermediate)  
**Duration**: 1.5 hours  
**Prerequisites**: TF-201 (Module Design & Composition)

---

## 📋 Overview

This course teaches you how to drive Terraform infrastructure from YAML configuration files. You'll learn to use `yamldecode()` to parse YAML, create dynamic resources with for_each, validate YAML structures, and build configuration-as-data patterns that separate infrastructure logic from configuration values.

**Why YAML-Driven Configuration?**: Separating configuration from code makes infrastructure more maintainable, enables non-technical users to manage configurations, and supports GitOps workflows where configuration changes trigger deployments.

---

## 🎯 Learning Objectives

By the end of this course, you will be able to:

- ✅ Parse YAML files using `yamldecode()` function
- ✅ Create dynamic resources from YAML configuration
- ✅ Use locals and for_each with YAML data
- ✅ Design complex YAML structures for infrastructure
- ✅ Validate YAML configuration in Terraform
- ✅ Implement configuration-as-data patterns
- ✅ Handle YAML parsing errors gracefully
- ✅ Build reusable YAML-driven modules
- ✅ Separate configuration from infrastructure logic
- ✅ Enable GitOps workflows with YAML configs

---

## 📚 Course Structure

This course covers YAML-driven configuration patterns in a single comprehensive section with multiple examples and labs.

### Key Topics Covered

**YAML Fundamentals**:
- YAML syntax and structure
- yamldecode() function usage
- File path handling
- Error handling

**Dynamic Resources**:
- Creating resources from YAML lists
- Using for_each with YAML data
- Nested YAML structures
- Complex object mapping

**Validation**:
- YAML schema validation
- Type checking
- Required field validation
- Custom validation rules

**Best Practices**:
- Configuration organization
- Security considerations
- Version control
- Documentation standards

---

## 💻 Hands-On Lab 1: Basic YAML Configuration

### Objective
Create infrastructure from a simple YAML configuration file.

### Duration
15 minutes

### Implementation

#### 1. Create YAML Configuration

```yaml
# config/networks.yaml
networks:
  - name: "web-network"
    mode: "nat"
    cidr: "10.10.0.0/24"
    autostart: true
  
  - name: "app-network"
    mode: "nat"
    cidr: "10.20.0.0/24"
    autostart: true
  
  - name: "db-network"
    mode: "nat"
    cidr: "10.30.0.0/24"
    autostart: true
```

#### 2. Create Terraform Configuration

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

# Parse YAML file
locals {
  config = yamldecode(file("${path.module}/config/networks.yaml"))
}

# Create networks from YAML
resource "libvirt_network" "networks" {
  for_each = { for net in local.config.networks : net.name => net }
  
  name      = each.value.name
  mode      = each.value.mode
  addresses = [each.value.cidr]
  autostart = each.value.autostart
  
  dns {
    enabled = true
  }
  
  dhcp {
    enabled = true
  }
}

# Outputs
output "network_ids" {
  description = "Map of network names to IDs"
  value = {
    for name, net in libvirt_network.networks :
    name => net.id
  }
}

output "network_bridges" {
  description = "Map of network names to bridge names"
  value = {
    for name, net in libvirt_network.networks :
    name => net.bridge
  }
}
```

#### 3. Test the Configuration

```bash
terraform init
terraform plan
terraform apply

# View outputs
terraform output network_ids
```

### Key Takeaways

- ✅ `yamldecode()` parses YAML into Terraform data structures
- ✅ `for_each` creates multiple resources from YAML lists
- ✅ Configuration is separated from infrastructure code
- ✅ Easy to add/remove networks by editing YAML

---

## 💻 Hands-On Lab 2: Complex YAML Structure

### Objective
Create a complete VM infrastructure from a complex YAML configuration.

### Duration
25 minutes

### YAML Configuration

```yaml
# config/infrastructure.yaml
environment: "production"
region: "us-east"

networks:
  web:
    name: "web-tier"
    cidr: "10.10.0.0/24"
    mode: "nat"
  app:
    name: "app-tier"
    cidr: "10.20.0.0/24"
    mode: "nat"
  db:
    name: "db-tier"
    cidr: "10.30.0.0/24"
    mode: "nat"

storage:
  pool_path: "/var/lib/libvirt/images/prod"
  base_image: "/var/lib/libvirt/images/ubuntu-22.04.qcow2"

virtual_machines:
  - name: "web-01"
    tier: "web"
    memory_mb: 2048
    vcpu_count: 2
    disk_size_gb: 20
    packages:
      - nginx
      - certbot
    
  - name: "web-02"
    tier: "web"
    memory_mb: 2048
    vcpu_count: 2
    disk_size_gb: 20
    packages:
      - nginx
      - certbot
  
  - name: "app-01"
    tier: "app"
    memory_mb: 4096
    vcpu_count: 4
    disk_size_gb: 50
    packages:
      - docker.io
      - docker-compose
  
  - name: "app-02"
    tier: "app"
    memory_mb: 4096
    vcpu_count: 4
    disk_size_gb: 50
    packages:
      - docker.io
      - docker-compose
  
  - name: "db-01"
    tier: "db"
    memory_mb: 8192
    vcpu_count: 8
    disk_size_gb: 100
    packages:
      - postgresql
      - postgresql-contrib
```

### Terraform Configuration

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

# Parse YAML configuration
locals {
  config = yamldecode(file("${path.module}/config/infrastructure.yaml"))
  
  # Create network map for easy lookup
  network_map = {
    for tier, net in local.config.networks :
    tier => net
  }
}

# Create networks
resource "libvirt_network" "tiers" {
  for_each = local.config.networks
  
  name      = each.value.name
  mode      = each.value.mode
  addresses = [each.value.cidr]
  autostart = true
  
  dns {
    enabled = true
  }
  
  dhcp {
    enabled = true
  }
}

# Create storage pool
resource "libvirt_pool" "main" {
  name = "${local.config.environment}-pool"
  type = "dir"
  path = local.config.storage.pool_path
}

# Create volumes for VMs
resource "libvirt_volume" "vm_disks" {
  for_each = { for vm in local.config.virtual_machines : vm.name => vm }
  
  name   = "${each.key}.qcow2"
  pool   = libvirt_pool.main.name
  source = local.config.storage.base_image
  size   = each.value.disk_size_gb * 1073741824 # Convert GB to bytes
  format = "qcow2"
}

# Create cloud-init disks
resource "libvirt_cloudinit_disk" "init" {
  for_each = { for vm in local.config.virtual_machines : vm.name => vm }
  
  name = "${each.key}-init.iso"
  pool = libvirt_pool.main.name
  
  user_data = templatefile("${path.module}/templates/cloud-init.tpl", {
    hostname = each.key
    packages = each.value.packages
  })
}

# Create VMs
resource "libvirt_domain" "vms" {
  for_each = { for vm in local.config.virtual_machines : vm.name => vm }
  
  name   = each.key
  memory = each.value.memory_mb
  vcpu   = each.value.vcpu_count
  
  cloudinit = libvirt_cloudinit_disk.init[each.key].id
  
  network_interface {
    network_id     = libvirt_network.tiers[each.value.tier].id
    wait_for_lease = true
  }
  
  disk {
    volume_id = libvirt_volume.vm_disks[each.key].id
  }
  
  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
  
  autostart = true
}

# Outputs organized by tier
output "infrastructure_summary" {
  description = "Complete infrastructure summary"
  value = {
    environment = local.config.environment
    region      = local.config.region
    
    networks = {
      for tier, net in libvirt_network.tiers :
      tier => {
        name   = net.name
        id     = net.id
        bridge = net.bridge
      }
    }
    
    vms_by_tier = {
      for tier in keys(local.config.networks) :
      tier => [
        for vm_name, vm in libvirt_domain.vms :
        {
          name = vm_name
          ip   = try(vm.network_interface[0].addresses[0], "")
        }
        if local.config.virtual_machines[index(local.config.virtual_machines.*.name, vm_name)].tier == tier
      ]
    }
  }
}
```

### Cloud-Init Template

```yaml
# templates/cloud-init.tpl
#cloud-config
hostname: ${hostname}
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
packages:
%{ for package in packages ~}
  - ${package}
%{ endfor ~}
runcmd:
  - echo "Setup complete for ${hostname}"
```

### Key Takeaways

- ✅ Complex nested YAML structures
- ✅ Multiple resource types from single config
- ✅ Tier-based organization
- ✅ Template integration with YAML data
- ✅ Comprehensive output organization

---

## 💻 Hands-On Lab 3: YAML Validation

### Objective
Implement validation for YAML configuration to catch errors early.

### Duration
20 minutes

### Validated Configuration

```hcl
# main.tf
locals {
  config = yamldecode(file("${path.module}/config/infrastructure.yaml"))
  
  # Validation: Check required fields
  validation_checks = {
    has_environment = can(local.config.environment)
    has_networks    = can(local.config.networks)
    has_vms         = can(local.config.virtual_machines)
  }
  
  # Validation: Check network structure
  network_validation = {
    for tier, net in local.config.networks :
    tier => {
      has_name = can(net.name)
      has_cidr = can(net.cidr)
      has_mode = can(net.mode)
      valid_cidr = can(cidrhost(net.cidr, 0))
      valid_mode = contains(["nat", "route", "bridge"], net.mode)
    }
  }
  
  # Validation: Check VM structure
  vm_validation = {
    for vm in local.config.virtual_machines :
    vm.name => {
      has_tier       = can(vm.tier)
      has_memory     = can(vm.memory_mb)
      has_vcpu       = can(vm.vcpu_count)
      has_disk       = can(vm.disk_size_gb)
      valid_tier     = contains(keys(local.config.networks), vm.tier)
      valid_memory   = vm.memory_mb >= 256 && vm.memory_mb <= 16384
      valid_vcpu     = vm.vcpu_count >= 1 && vm.vcpu_count <= 16
      valid_disk     = vm.disk_size_gb >= 10 && vm.disk_size_gb <= 1000
    }
  }
}

# Validation checks using check blocks
check "yaml_structure" {
  assert {
    condition     = alltrue(values(local.validation_checks))
    error_message = "YAML configuration missing required top-level fields"
  }
}

check "network_configuration" {
  assert {
    condition = alltrue(flatten([
      for tier, checks in local.network_validation :
      values(checks)
    ]))
    error_message = "Invalid network configuration detected"
  }
}

check "vm_configuration" {
  assert {
    condition = alltrue(flatten([
      for vm, checks in local.vm_validation :
      values(checks)
    ]))
    error_message = "Invalid VM configuration detected"
  }
}

# Additional validation using variables
variable "allowed_environments" {
  description = "Allowed environment names"
  type        = list(string)
  default     = ["dev", "staging", "production"]
}

check "environment_validation" {
  assert {
    condition     = contains(var.allowed_environments, local.config.environment)
    error_message = "Environment must be one of: ${join(", ", var.allowed_environments)}"
  }
}
```

### Validation Helper Module

```hcl
# modules/yaml-validator/main.tf
variable "yaml_path" {
  description = "Path to YAML file"
  type        = string
}

variable "required_fields" {
  description = "List of required top-level fields"
  type        = list(string)
  default     = []
}

locals {
  config = yamldecode(file(var.yaml_path))
  
  # Check all required fields exist
  field_checks = {
    for field in var.required_fields :
    field => can(local.config[field])
  }
  
  all_fields_present = alltrue(values(local.field_checks))
}

output "config" {
  description = "Parsed configuration"
  value       = local.config
}

output "validation_passed" {
  description = "Whether validation passed"
  value       = local.all_fields_present
}

output "missing_fields" {
  description = "List of missing required fields"
  value = [
    for field, present in local.field_checks :
    field if !present
  ]
}
```

### Usage

```hcl
module "config_validator" {
  source = "./modules/yaml-validator"
  
  yaml_path = "${path.module}/config/infrastructure.yaml"
  required_fields = [
    "environment",
    "networks",
    "storage",
    "virtual_machines"
  ]
}

# Use validated config
locals {
  validated_config = module.config_validator.config
}

# Check validation passed
check "config_validation" {
  assert {
    condition     = module.config_validator.validation_passed
    error_message = "Configuration validation failed. Missing fields: ${join(", ", module.config_validator.missing_fields)}"
  }
}
```

### Key Takeaways

- ✅ Validate YAML structure before use
- ✅ Check required fields exist
- ✅ Validate data types and ranges
- ✅ Use check blocks for assertions
- ✅ Provide clear error messages

---

## 📝 Checkpoint Quiz

### Question 1: YAML Parsing
**Which function is used to parse YAML files in Terraform?**

A) yaml_parse()  
B) yamldecode()  
C) parse_yaml()  
D) decode_yaml()

<details>
<summary>Show Answer</summary>

**Answer: B** - yamldecode()

**Explanation**: The `yamldecode()` function parses YAML-formatted strings and returns a Terraform data structure:

```hcl
locals {
  config = yamldecode(file("config.yaml"))
}
```

Other functions:
- `jsondecode()` - Parse JSON
- `file()` - Read file contents
- `templatefile()` - Render templates
</details>

---

### Question 2: Dynamic Resources
**What is the best way to create multiple resources from a YAML list?**

A) count  
B) for_each  
C) dynamic blocks  
D) Multiple resource blocks

<details>
<summary>Show Answer</summary>

**Answer: B** - for_each

**Explanation**: `for_each` with a map provides stable resource addresses:

```hcl
locals {
  config = yamldecode(file("config.yaml"))
}

resource "libvirt_network" "networks" {
  for_each = { for net in local.config.networks : net.name => net }
  
  name = each.value.name
  # ...
}
```

This creates resources with addresses like:
- `libvirt_network.networks["web-network"]`
- `libvirt_network.networks["app-network"]`

Removing one doesn't affect others.
</details>

---

### Question 3: Configuration Separation
**What is the PRIMARY benefit of YAML-driven configuration?**

A) Faster Terraform execution  
B) Smaller state files  
C) Separation of configuration from infrastructure logic  
D) Automatic error handling

<details>
<summary>Show Answer</summary>

**Answer: C** - Separation of configuration from infrastructure logic

**Explanation**: YAML-driven configuration provides:
- **Separation of concerns**: Config vs. logic
- **Non-technical access**: YAML is easier than HCL
- **GitOps workflows**: Config changes trigger deployments
- **Reusability**: Same Terraform code, different configs
- **Maintainability**: Update config without touching code

Example:
```
terraform/          # Infrastructure logic (rarely changes)
├── main.tf
└── modules/

config/             # Configuration data (changes frequently)
├── dev.yaml
├── staging.yaml
└── production.yaml
```
</details>

---

### Question 4: Error Handling
**How can you handle missing YAML files gracefully?**

A) Use try() function  
B) Use can() function  
C) Use fileexists() function  
D) All of the above

<details>
<summary>Show Answer</summary>

**Answer: D** - All of the above

**Explanation**: Multiple approaches for error handling:

```hcl
# Check if file exists
locals {
  config_file = "${path.module}/config.yaml"
  config = fileexists(local.config_file) ? yamldecode(file(local.config_file)) : {}
}

# Try to parse, use default if fails
locals {
  config = try(yamldecode(file("config.yaml")), {
    networks = []
    vms = []
  })
}

# Check if field exists
locals {
  environment = can(local.config.environment) ? local.config.environment : "dev"
}
```
</details>

---

### Question 5: YAML Validation
**When should you validate YAML configuration?**

A) Only in production  
B) During terraform plan  
C) After terraform apply  
D) Never, Terraform handles it

<details>
<summary>Show Answer</summary>

**Answer: B** - During terraform plan

**Explanation**: Validate early to catch errors before applying:

```hcl
# Validation during plan phase
check "config_validation" {
  assert {
    condition     = can(local.config.environment)
    error_message = "Missing required field: environment"
  }
}

# Variable validation
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Invalid environment"
  }
}
```

Early validation prevents:
- Partial infrastructure creation
- Wasted time and resources
- Difficult rollbacks
</details>

---

### Question 6: Complex Structures
**How do you access nested YAML values in Terraform?**

A) Using dot notation  
B) Using bracket notation  
C) Using lookup() function  
D) All of the above

<details>
<summary>Show Answer</summary>

**Answer: D** - All of the above

**Explanation**: Multiple ways to access nested values:

```yaml
# config.yaml
app:
  name: "my-app"
  settings:
    memory: 2048
```

```hcl
locals {
  config = yamldecode(file("config.yaml"))
  
  # Dot notation
  app_name = local.config.app.name
  
  # Bracket notation
  memory = local.config["app"]["settings"]["memory"]
  
  # lookup() with default
  vcpu = lookup(local.config.app.settings, "vcpu", 2)
  
  # try() for optional fields
  disk = try(local.config.app.settings.disk, 20)
}
```
</details>

---

## 📖 Best Practices

### 1. Configuration Organization

```
project/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── modules/
└── config/
    ├── dev.yaml
    ├── staging.yaml
    └── production.yaml
```

**Benefits**:
- Clear separation of code and config
- Easy to find and update configurations
- Version control friendly
- Environment-specific configs

---

### 2. YAML Schema Documentation

```yaml
# config/schema.yaml (documentation)
# This file documents the expected YAML structure

environment: string  # Required: dev, staging, production
region: string       # Required: deployment region

networks:            # Required: map of network configurations
  <tier_name>:
    name: string     # Required: network name
    cidr: string     # Required: CIDR block (e.g., "10.0.0.0/24")
    mode: string     # Required: nat, route, or bridge

virtual_machines:    # Required: list of VM configurations
  - name: string     # Required: VM name
    tier: string     # Required: must match network tier
    memory_mb: number # Required: 256-16384
    vcpu_count: number # Required: 1-16
    disk_size_gb: number # Required: 10-1000
    packages: list   # Optional: list of packages to install
```

---

### 3. Security Considerations

```hcl
# ❌ BAD: Secrets in YAML
# config.yaml
database:
  password: "super-secret-password"  # Don't do this!

# ✅ GOOD: Reference secrets from secure storage
# config.yaml
database:
  password_secret_name: "db-password"

# main.tf
data "external" "secrets" {
  program = ["bash", "-c", "vault kv get -format=json secret/db"]
}

locals {
  config = yamldecode(file("config.yaml"))
  db_password = jsondecode(data.external.secrets.result.data)["password"]
}
```

**Security Best Practices**:
- Never store secrets in YAML files
- Use secret management systems (Vault, AWS Secrets Manager)
- Encrypt sensitive YAML files at rest
- Use `.gitignore` for sensitive configs
- Implement access controls

---

### 4. Version Control

```gitignore
# .gitignore

# Sensitive configurations
config/*-secrets.yaml
config/production.yaml  # If contains sensitive data

# Local overrides
config/local.yaml
config/*.local.yaml

# Terraform files
.terraform/
*.tfstate
*.tfstate.*
```

**Version Control Best Practices**:
- Commit non-sensitive configs
- Use separate files for secrets
- Document config structure
- Use meaningful commit messages
- Review config changes carefully

---

### 5. Error Handling

```hcl
# Comprehensive error handling
locals {
  # Check file exists
  config_file = "${path.module}/config/${var.environment}.yaml"
  file_exists = fileexists(local.config_file)
  
  # Parse with error handling
  raw_config = local.file_exists ? file(local.config_file) : "{}"
  config = try(yamldecode(local.raw_config), {})
  
  # Provide defaults for missing fields
  environment = try(local.config.environment, var.environment)
  networks = try(local.config.networks, {})
  vms = try(local.config.virtual_machines, [])
}

# Validate configuration
check "config_file_exists" {
  assert {
    condition     = local.file_exists
    error_message = "Configuration file not found: ${local.config_file}"
  }
}

check "config_not_empty" {
  assert {
    condition     = length(keys(local.config)) > 0
    error_message = "Configuration file is empty or invalid"
  }
}
```

---

## 🔧 Advanced Patterns

### Pattern 1: Multi-Environment Configuration

```hcl
# main.tf
variable "environment" {
  description = "Environment name"
  type        = string
}

locals {
  # Load environment-specific config
  config = yamldecode(file("${path.module}/config/${var.environment}.yaml"))
  
  # Merge with common config
  common_config = yamldecode(file("${path.module}/config/common.yaml"))
  
  # Final configuration
  final_config = merge(local.common_config, local.config)
}
```

```yaml
# config/common.yaml
storage:
  base_image: "/var/lib/libvirt/images/ubuntu-22.04.qcow2"
  
defaults:
  memory_mb: 1024
  vcpu_count: 2
  disk_size_gb: 20
```

```yaml
# config/production.yaml
environment: "production"
region: "us-east"

networks:
  web:
    name: "prod-web"
    cidr: "10.10.0.0/24"

virtual_machines:
  - name: "prod-web-01"
    tier: "web"
    memory_mb: 4096  # Override default
    vcpu_count: 4    # Override default
```

---

### Pattern 2: YAML Templates

```yaml
# config/template.yaml
environment: "${environment}"
region: "${region}"

networks:
  web:
    name: "${environment}-web"
    cidr: "10.10.0.0/24"
```

```hcl
# main.tf
locals {
  # Render template
  config_template = templatefile("${path.module}/config/template.yaml", {
    environment = var.environment
    region      = var.region
  })
  
  # Parse rendered YAML
  config = yamldecode(local.config_template)
}
```

---

### Pattern 3: Configuration Inheritance

```yaml
# config/base.yaml
defaults:
  memory_mb: 1024
  vcpu_count: 2
  disk_size_gb: 20
  packages:
    - curl
    - vim

# config/web-tier.yaml
inherits: "base"
overrides:
  packages:
    - nginx
    - certbot
```

```hcl
# main.tf
locals {
  base_config = yamldecode(file("config/base.yaml"))
  tier_config = yamldecode(file("config/web-tier.yaml"))
  
  # Merge configurations
  final_config = merge(
    local.base_config.defaults,
    local.tier_config.overrides
  )
}
```

---

## 📚 Additional Resources

### Official Documentation
- [Terraform Functions](https://developer.hashicorp.com/terraform/language/functions)
- [yamldecode() Function](https://developer.hashicorp.com/terraform/language/functions/yamldecode)
- [file() Function](https://developer.hashicorp.com/terraform/language/functions/file)
- [for_each Meta-Argument](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each)

### YAML Resources
- [YAML Specification](https://yaml.org/spec/)
- [YAML Syntax Guide](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html)
- [YAML Validator](https://www.yamllint.com/)

### Best Practices
- [Configuration as Data](https://www.hashicorp.com/resources/configuration-as-data-with-terraform)
- [GitOps with Terraform](https://www.gitops.tech/)

---

## 📦 Supplemental Content

Extend your TF-203 knowledge with these additional topics:

| Section | Topic | Description |
|---------|-------|-------------|
| [json-config/](json-config/README.md) | `jsondecode()` & JSON-Driven Config | Parse JSON files, use `jsonencode()` for inline policies, choose JSON vs YAML |

---

## 🎉 Congratulations!

You've completed TF-203: YAML-Driven Configuration!

### What You've Learned

- ✅ Parsing YAML with `yamldecode()`
- ✅ Creating dynamic resources from YAML
- ✅ Complex YAML structure handling
- ✅ YAML validation strategies
- ✅ Configuration-as-data patterns
- ✅ Error handling and defaults
- ✅ Security best practices
- ✅ Multi-environment configurations
- ✅ Parsing JSON with `jsondecode()` *(Supplemental)*
- ✅ Generating JSON output with `jsonencode()` *(Supplemental)*
- ✅ Choosing JSON vs YAML for different use cases *(Supplemental)*

### Next Steps

**Continue to TF-204**: Import & Migration Strategies
- Import existing infrastructure
- Migrate legacy code
- State manipulation techniques
- Refactoring strategies

---

**Ready to learn infrastructure import and migration?** Continue to TF-204! 🚀

---

*This course demonstrates configuration-as-data patterns applicable to all Terraform providers. YAML-driven configuration enables GitOps workflows and separates infrastructure logic from configuration values.*