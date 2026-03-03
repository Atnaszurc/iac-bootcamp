# Course Catalog

**Purpose**: Complete descriptions of all courses in the hashi-training program.

---

## 📚 Overview

This catalog provides detailed information about each course, including:
- Learning objectives
- Prerequisites
- Duration
- Topics covered
- Hands-on exercises
- Key takeaways

---

## 🎯 Course Numbering System

Courses follow a university-style numbering system:

- **100-level**: Fundamentals (beginner)
- **200-level**: Intermediate (requires 100-level knowledge)
- **300-level**: Advanced (requires 200-level knowledge)
- **400-level**: Expert (requires 300-level knowledge)

**Prefix Meanings**:
- **TF**: Terraform courses
- **PKR**: Packer courses
- **AWS**: AWS-specific courses
- **AZ**: Azure-specific courses
- **MC**: Multi-cloud courses

---

## 🏗️ Core Training Courses

### TF-100 Series: Terraform Fundamentals (6 hours)

#### TF-101: Introduction to IaC & Terraform Basics
**Duration**: 1.5 hours  
**Level**: Beginner  
**Prerequisites**: None  
**Location**: `TF-100-fundamentals/TF-101-intro-basics/`

**Description**:
Your first steps into Infrastructure as Code. This course introduces the fundamental concepts of IaC and Terraform, explaining why managing infrastructure as code is crucial in modern DevOps practices.

**Learning Objectives**:
- Understand what Infrastructure as Code is and why it matters
- Learn how Terraform works (declarative vs imperative)
- Understand the Terraform workflow (init → plan → apply)
- Configure and use providers
- Create your first infrastructure resources
- Master basic HCL syntax

**Topics Covered**:
1. What is Infrastructure as Code?
2. Terraform architecture and workflow
3. Providers and their role
4. Basic resource creation
5. HCL syntax fundamentals
6. Introduction to Libvirt provider

**Hands-On Exercises**:
- Install Terraform and Libvirt
- Create local files with `local_file` provider
- Configure Libvirt provider
- Create your first virtual network
- Run `terraform init`, `plan`, and `apply`

**Key Takeaways**:
- ✅ Understand IaC principles
- ✅ Know Terraform's declarative approach
- ✅ Can write basic Terraform configurations
- ✅ Understand provider configuration
- ✅ Can execute basic Terraform workflow

---

#### TF-102: Variables, Loops & Functions
**Duration**: 1.5 hours  
**Level**: Beginner  
**Prerequisites**: TF-101  
**Location**: `TF-100-fundamentals/TF-102-variables-loops/`

**Description**:
Make your Terraform configurations dynamic and reusable. Learn how to use variables, loops, and functions to create flexible infrastructure code that adapts to different environments and requirements.

**Learning Objectives**:
- Declare and use variables effectively
- Implement loops for resource creation
- Read configuration from environment variables
- Apply Terraform functions to manipulate data
- Create DRY (Don't Repeat Yourself) configurations

**Topics Covered**:
1. **Variables** (1-variables/)
   - Variable types (string, number, bool, list, map, object)
   - Default values and validation
   - Variable precedence
   - Sensitive variables

2. **Loops** (2-loops/)
   - `count` parameter
   - `for_each` with maps and sets
   - Dynamic blocks
   - When to use each approach

3. **Environment Variables** (3-env-vars/)
   - TF_VAR_ prefix
   - Reading from .env files
   - Variable files (.tfvars)
   - CLI variable passing

4. **Functions** (4-functions/)
   - String functions (upper, lower, format)
   - Collection functions (length, merge, concat)
   - Encoding functions (jsonencode, yamldecode)
   - Filesystem functions (file, templatefile)

**Hands-On Exercises**:
- Create parameterized network configurations
- Use loops to create multiple VMs
- Read configuration from environment variables
- Apply functions to transform data
- Build a reusable module with variables

**Key Takeaways**:
- ✅ Can create flexible configurations with variables
- ✅ Know when to use count vs for_each
- ✅ Can manage configuration across environments
- ✅ Understand common Terraform functions
- ✅ Can write DRY infrastructure code

---

#### TF-103: Infrastructure Resources
**Duration**: 2 hours  
**Level**: Beginner  
**Prerequisites**: TF-102  
**Location**: `TF-100-fundamentals/TF-103-infrastructure/`

**Description**:
Build real infrastructure with Terraform. This course covers creating networks, security configurations, and virtual machines using the Libvirt provider. Learn how resources depend on each other and how to manage complex infrastructure.

**Learning Objectives**:
- Create and manage virtual networks
- Configure network security
- Launch and manage virtual machines
- Understand resource dependencies
- Use data sources to reference existing resources
- Manage infrastructure lifecycle

**Topics Covered**:
1. **Networks** (1-networks/)
   - Virtual network creation
   - DHCP configuration
   - DNS settings
   - Network modes (NAT, bridge, isolated)
   - IP address management

2. **Security** (2-security/)
   - Network isolation
   - Firewall concepts
   - Security best practices
   - Access control

3. **Virtual Machines** (3-virtual-machines/)
   - VM creation with libvirt_domain
   - Cloud-init configuration
   - Disk management with libvirt_volume
   - CPU and memory allocation
   - Network attachment
   - VM lifecycle management

**Hands-On Exercises**:
- Create isolated virtual networks
- Configure DHCP and DNS
- Launch multiple VMs with cloud-init
- Connect VMs to networks
- Manage VM lifecycle (start, stop, destroy)
- Use data sources to reference networks

**Key Takeaways**:
- ✅ Can create virtual networks
- ✅ Understand network security concepts
- ✅ Can launch and manage VMs
- ✅ Understand resource dependencies
- ✅ Can use data sources effectively
- ✅ Ready to apply concepts to cloud providers

**Real-World Connection**:
These concepts directly translate to:
- **AWS**: VPC → EC2, Security Groups
- **Azure**: VNet → VMs, NSGs
- **Any cloud provider's networking and compute**

---

#### TF-104: State Management & CLI
**Duration**: 1 hour  
**Level**: Beginner  
**Prerequisites**: TF-103  
**Location**: `TF-100-fundamentals/TF-104-state-cli/`

**Description**:
Master Terraform's command-line interface and understand state management. Learn essential CLI commands, how Terraform tracks infrastructure, and get introduced to modules for code organization.

**Learning Objectives**:
- Master all essential Terraform CLI commands
- Understand Terraform state and its importance
- Learn state management best practices
- Create basic modules
- Debug Terraform configurations
- Troubleshoot common issues

**Topics Covered**:
1. **CLI Commands** (1-cli/)
   - `terraform init` - Initialize working directory
   - `terraform fmt` - Format code
   - `terraform validate` - Validate configuration
   - `terraform plan` - Preview changes
   - `terraform apply` - Apply changes
   - `terraform destroy` - Destroy infrastructure
   - `terraform console` - Interactive console
   - `terraform output` - View outputs
   - `terraform show` - Inspect state

2. **State Management** (2-state/)
   - What is Terraform state?
   - State file structure
   - Why state is critical
   - State locking
   - Remote state backends
   - State security considerations

3. **Module Basics** (3-modules-intro/)
   - What are modules?
   - Module structure
   - Creating your first module
   - Module inputs and outputs
   - Module versioning basics

4. **Debugging** (4-debugging/)
   - TF_LOG environment variable
   - Common error messages
   - Debugging strategies
   - Using terraform console
   - State inspection techniques

**Hands-On Exercises**:
- Use all major CLI commands
- Inspect and understand state files
- Create a simple reusable module
- Debug intentional errors
- Use terraform console for testing

**Key Takeaways**:
- ✅ Proficient with Terraform CLI
- ✅ Understand state management
- ✅ Can create basic modules
- ✅ Can debug Terraform issues
- ✅ Ready for advanced Terraform topics

---

### TF-200 Series: Terraform Modules (6 hours)

#### TF-201: Module Design & Composition
**Duration**: 1.5 hours  
**Level**: Intermediate  
**Prerequisites**: TF-100 series  
**Location**: `TF-200-modules/TF-201-module-design/`

**Description**:
Learn professional module design patterns. This course teaches you how to create well-structured, reusable modules and how to compose them together to build complex infrastructure.

**Learning Objectives**:
- Design modules following best practices
- Implement module composition (modules calling modules)
- Use optional attributes effectively
- Create dynamic blocks for flexibility
- Version modules properly
- Document modules professionally

**Topics Covered**:
- Module design principles
- Input variable design
- Output design for composition
- Optional attributes (Terraform 1.3+)
- Dynamic blocks
- Module composition patterns
- Module documentation
- Versioning strategies

**Hands-On Exercises**:
- Design a network module
- Create a VM module that uses the network module
- Implement optional attributes
- Use dynamic blocks for flexibility
- Compose modules together
- Document modules with examples

**Key Takeaways**:
- ✅ Can design professional modules
- ✅ Understand module composition
- ✅ Can use optional attributes
- ✅ Know module best practices
- ✅ Can create reusable infrastructure components

---

#### TF-202: Advanced Module Patterns
**Duration**: 1.5 hours  
**Level**: Intermediate  
**Prerequisites**: TF-201  
**Location**: `TF-200-modules/TF-202-advanced-patterns/`

**Description**:
Implement enterprise-grade deployment patterns. Learn how to publish modules to private registries, implement canary and blue-green deployments, and collaborate effectively with teams.

**Learning Objectives**:
- Publish modules to HCP Terraform (Terraform Cloud)
- Implement canary deployments
- Implement blue-green deployments
- Version modules semantically
- Collaborate with teams using modules
- Manage module dependencies

**Topics Covered**:
1. **Private Module Registry** (1-private-registry/)
   - HCP Terraform setup
   - Publishing modules
   - Module versioning
   - Module discovery
   - Access control

2. **Canary Deployments** (2-canary-deployments/)
   - What is canary deployment?
   - Implementing with modules
   - Traffic splitting
   - Rollback strategies
   - Monitoring and validation

**Hands-On Exercises**:
- Set up HCP Terraform account
- Publish a module to private registry
- Implement canary deployment pattern
- Test deployment strategies
- Practice rollback procedures

**Key Takeaways**:
- ✅ Can publish modules to registries
- ✅ Understand deployment patterns
- ✅ Can implement canary deployments
- ✅ Know team collaboration workflows
- ✅ Ready for production deployments

---

#### TF-203: YAML-Driven Configuration
**Duration**: 1.5 hours  
**Level**: Intermediate  
**Prerequisites**: TF-201  
**Location**: `TF-200-modules/TF-203-yaml-config/`

**Description**:
Use YAML files to drive infrastructure creation. Learn when and how to use data-driven configuration, making your infrastructure more maintainable and accessible to non-Terraform experts.

**Learning Objectives**:
- Parse YAML files in Terraform
- Create resources dynamically from YAML
- Validate YAML input
- Understand when to use YAML vs HCL
- Implement data-driven infrastructure
- Use locals for complex transformations

**Topics Covered**:
- YAML parsing with yamldecode()
- Dynamic resource creation
- Input validation
- YAML schema design
- When to use YAML vs HCL
- Complex data transformations
- Error handling

**Hands-On Exercises**:
- Create YAML configuration files
- Parse YAML in Terraform
- Create multiple resources from YAML
- Implement validation
- Build a YAML-driven network configuration

**Key Takeaways**:
- ✅ Can use YAML for configuration
- ✅ Understand data-driven infrastructure
- ✅ Know when to use YAML vs HCL
- ✅ Can validate YAML input
- ✅ Can build flexible configuration systems

---

#### TF-204: Import & Migration Strategies
**Duration**: 1.5 hours  
**Level**: Intermediate  
**Prerequisites**: TF-201  
**Location**: `TF-200-modules/TF-204-import-migration/`

**Description**:
Bring existing infrastructure under Terraform management. Learn how to import resources, generate configuration, and plan migrations from manual infrastructure to Infrastructure as Code.

**Learning Objectives**:
- Import existing infrastructure
- Generate Terraform configuration from imports
- Plan migration strategies
- Handle state during imports
- Migrate incrementally
- Avoid common import pitfalls

**Topics Covered**:
- Import blocks (Terraform 1.5+)
- Generating configuration
- Import strategies
- State management during imports
- Incremental migration
- Testing imported resources
- Refactoring after import

**Hands-On Exercises**:
- Import existing Libvirt resources
- Generate configuration from imports
- Plan a migration strategy
- Import resources incrementally
- Validate imported infrastructure
- Refactor imported code

**Key Takeaways**:
- ✅ Can import existing infrastructure
- ✅ Can generate configuration
- ✅ Understand migration strategies
- ✅ Can handle state during imports
- ✅ Ready to migrate production infrastructure

---

### TF-300 Series: Testing, Validation & Advanced Features (8 hours)

#### TF-301: Input Validation & Advanced Functions
**Duration**: 1.5 hours  
**Level**: Advanced  
**Prerequisites**: TF-200 series  
**Location**: `TF-300-advanced/TF-301-validation/`

**Description**:
Implement comprehensive input validation. Learn how to validate variables, use advanced functions, and ensure configuration correctness before infrastructure deployment.

**Learning Objectives**:
- Write variable validation rules
- Implement cross-variable validation
- Use advanced Terraform functions
- Use provider-defined functions (Azure)
- Create custom validation logic
- Provide helpful error messages

**Topics Covered**:
1. **Variable Conditions** (1-variable-conditions/)
   - Validation blocks (Terraform 1.14+)
   - Condition expressions
   - Error messages
   - Cross-variable validation
   - Complex validation logic

2. **Advanced Functions** (2-advanced-functions/)
   - Type conversion functions
   - try() for error handling
   - can() for capability testing
   - Provider-defined functions
   - Custom function patterns

**Hands-On Exercises**:
- Write validation rules for variables
- Implement cross-variable validation
- Use try() and can() functions
- Create helpful error messages
- Test validation logic

**Key Takeaways**:
- ✅ Can validate input comprehensively
- ✅ Understand advanced functions
- ✅ Can provide helpful error messages
- ✅ Know validation best practices
- ✅ Can prevent configuration errors

---

#### TF-302: Pre/Post Conditions & Check Blocks
**Duration**: 1.5 hours  
**Level**: Advanced  
**Prerequisites**: TF-301  
**Location**: `TF-300-advanced/TF-302-conditions-checks/`

**Description**:
Implement runtime validation with preconditions, postconditions, and check blocks. Learn how to validate infrastructure state before and after operations, ensuring correctness throughout the lifecycle.

**Learning Objectives**:
- Implement preconditions on resources
- Implement postconditions on resources
- Use check blocks for final validation
- Understand when to use each validation type
- Create comprehensive validation strategies
- Handle validation failures gracefully

**Topics Covered**:
1. **Pre/Post Conditions** (1-pre-postconditions/)
   - Preconditions (before resource operations)
   - Postconditions (after resource operations)
   - Lifecycle validation
   - Error handling
   - Best practices

2. **Check Blocks** (2-check-blocks/)
   - Check block syntax
   - Continuous validation
   - Data source checks
   - HTTP checks
   - Custom checks

**Hands-On Exercises**:
- Implement preconditions on VMs
- Add postconditions to verify state
- Create check blocks for monitoring
- Test validation failures
- Build comprehensive validation

**Key Takeaways**:
- ✅ Can validate at all lifecycle stages
- ✅ Understand preconditions vs postconditions
- ✅ Can use check blocks effectively
- ✅ Know when to use each validation type
- ✅ Can build robust infrastructure

---

#### TF-303: Terraform Test Framework
**Duration**: 1 hour  
**Level**: Advanced  
**Prerequisites**: TF-302  
**Location**: `TF-300-advanced/TF-303-test-framework/` **[PLANNED]**

**Description**:
Write comprehensive tests for Terraform modules. Learn the Terraform Test Framework to ensure your modules work correctly across different scenarios and configurations.

**Learning Objectives**:
- Write Terraform tests
- Organize test files
- Use mock providers
- Test different scenarios
- Integrate tests into CI/CD
- Measure test coverage

**Topics Covered**:
- Test file structure (.tftest.hcl)
- Test organization
- Mock providers
- Test scenarios
- Assertions
- CI/CD integration
- Test best practices

**Hands-On Exercises**:
- Write basic tests
- Test module variations
- Use mock providers
- Run tests in CI/CD
- Measure coverage

**Key Takeaways**:
- ✅ Can write Terraform tests
- ✅ Understand test organization
- ✅ Can use mock providers
- ✅ Know testing best practices
- ✅ Can integrate tests into CI/CD

---

#### TF-304: Policy as Code
**Duration**: 1 hour  
**Level**: Advanced  
**Prerequisites**: TF-303  
**Location**: `TF-300-advanced/TF-304-policy-code/` **[PLANNED]**

**Description**:
Enforce organizational policies with code. Learn how to write and test policies using OPA/Rego or Sentinel to ensure compliance and security across all infrastructure.

**Learning Objectives**:
- Write policy as code
- Test policies
- Enforce policies
- Implement compliance automation
- Handle policy violations
- Integrate with CI/CD

**Topics Covered**:
- Policy as code concepts
- OPA/Rego or Sentinel
- Policy testing
- Enforcement levels
- Compliance automation
- Policy libraries
- CI/CD integration

**Hands-On Exercises**:
- Write security policies
- Test policies
- Enforce policies
- Handle violations
- Build policy library

**Key Takeaways**:
- ✅ Can write policies as code
- ✅ Understand policy enforcement
- ✅ Can test policies
- ✅ Know compliance automation
- ✅ Can ensure organizational standards

---

#### TF-305: Workspaces & Remote State
**Duration**: 1.5 hours
**Level**: Advanced
**Prerequisites**: TF-104, TF-201
**Location**: `TF-300-advanced/TF-305-workspaces-remote-state/`

**Description**:
Master state management for teams and production environments. Move beyond local state to remote backends, workspace strategies, and HCP Terraform — the complete HashiCorp-native story for collaborative Terraform workflows.

**Learning Objectives**:
- Use CLI workspaces for state isolation
- Configure remote backends (HCP Terraform, S3, Azure Blob)
- Share state between configurations with `terraform_remote_state`
- Migrate local state to HCP Terraform
- Understand state locking and history

**Topics Covered**:
1. **Workspaces** (1-workspaces/)
   - `terraform workspace` commands
   - `terraform.workspace` interpolation
   - Workspace-driven configuration
   - Anti-pattern: workspaces ≠ environments

2. **Remote Backends** (2-remote-backends/)
   - HCP Terraform `cloud` block
   - Azure Blob Storage (`azurerm`)
   - AWS S3 + DynamoDB (`s3`)
   - State locking comparison

3. **Remote State Sharing** (3-remote-state-sharing/)
   - `terraform_remote_state` data source
   - Layered infrastructure architecture
   - Producer/consumer pattern

4. **HCP Terraform State** (4-hcp-terraform-state/)
   - Free tier (500 resources)
   - State history and rollback
   - Migrating from local state

**Hands-On Exercises**:
- Create and switch between workspaces
- Configure a remote backend
- Share state between two configurations
- Migrate local state to HCP Terraform

**Key Takeaways**:
- ✅ Can configure remote backends
- ✅ Understand workspace use cases and anti-patterns
- ✅ Can share state between configurations
- ✅ Know HCP Terraform as the recommended backend
- ✅ Ready for team-based Terraform workflows

---

#### TF-306: Terraform Functions Deep Dive
**Duration**: 1.5 hours
**Level**: Advanced
**Prerequisites**: TF-102, TF-201
**Location**: `TF-300-advanced/TF-306-functions/`

**Description**:
A systematic deep dive into four essential function categories. Move beyond basic string functions to master collection transformation, file-based configuration, and data encoding — the building blocks of production-grade Terraform code.

**Learning Objectives**:
- Apply advanced string functions for naming and text processing
- Transform collections with flatten, merge, setproduct, and zipmap
- Load external configuration using file, templatefile, and fileset
- Convert data between JSON, YAML, and Base64 formats
- Combine multiple functions to solve real infrastructure problems

**Topics Covered**:
1. **String Functions** (1-string-functions/)
   - `format()` / `formatlist()` — printf-style formatting
   - `regex()` / `regexall()` — pattern matching
   - `replace()`, `split()`, `join()`, `substr()`
   - `trim()`, `trimprefix()`, `trimsuffix()`

2. **Collection Functions** (2-collection-functions/)
   - `flatten()` — collapse nested lists
   - `merge()` — combine maps
   - `setproduct()` — cartesian product
   - `zipmap()` — build maps from key/value lists
   - `distinct()`, `compact()`, `concat()`

3. **Filesystem Functions** (3-filesystem-functions/)
   - `file()` — read raw file contents
   - `templatefile()` — render `.tftpl` templates
   - `fileset()` — discover files by glob pattern
   - `filebase64()` — binary-safe file encoding

4. **Encoding Functions** (4-encoding-functions/)
   - `jsonencode()` / `jsondecode()` — HCL ↔ JSON
   - `yamlencode()` / `yamldecode()` — HCL ↔ YAML
   - `base64encode()` / `base64decode()`
   - `tostring()`, `tonumber()`, `tobool()`, `toset()`

**Hands-On Exercises**:
- Build consistent resource naming with `format()` and `lower()`
- Generate multi-region deployment matrices with `setproduct()`
- Render cloud-init configs with `templatefile()` loops
- Generate IAM policies dynamically with `jsonencode()` + `for`

**Key Takeaways**:
- ✅ Can apply advanced string manipulation
- ✅ Can transform collections for dynamic resource creation
- ✅ Can load and render external configuration files
- ✅ Can convert data between JSON, YAML, and Base64
- ✅ Ready to write production-grade Terraform code

---

#### TF-307: List Resources, terraform query & Actions (NEW — 1.14)
**Duration**: 1 hour
**Level**: Advanced
**Prerequisites**: TF-104, TF-204
**Location**: `TF-300-advanced/TF-307-query-actions/`
**Terraform Version**: 1.14+

**Description**:
Explore two powerful new paradigms introduced in Terraform 1.14: **list resources** for querying existing infrastructure without managing it, and **actions** for provider-defined imperative operations. These features bridge the gap between declarative IaC and operational tasks.

**Learning Objectives**:
- Understand list resources and the `.tfquery.hcl` file format
- Use `terraform query` to discover and filter existing infrastructure
- Generate import configuration from query results
- Understand the Actions block for provider-defined imperative operations
- Trigger actions automatically via resource lifecycle events
- Invoke actions manually with `terraform apply -invoke`
- Compare Actions vs `local-exec` provisioners vs `null_resource`

**Topics Covered**:
1. **List Resources** (Part 1)
   - What are list resources? (read-only, never in state)
   - `.tfquery.hcl` file format and `list` block syntax
   - `terraform query` command
   - `-generate-config-out` flag for import generation
   - Comparison: list resources vs data sources

2. **Actions Block** (Part 2)
   - What are Actions? (provider-defined imperative operations)
   - `action` block syntax
   - Trigger types: `after_create`, `after_update`, `after_apply`, `before_destroy`
   - Manual invocation: `terraform apply -invoke=<action>`
   - Actions vs `local-exec` vs `null_resource`

**Hands-On Exercises**:
- Write a `.tfquery.hcl` file to list existing resources
- Run `terraform query` to discover infrastructure
- Generate import configuration from query results
- Write an action block triggered after resource creation
- Manually invoke an action with `-invoke`

**Key Takeaways**:
- ✅ Can query existing infrastructure without managing it
- ✅ Can generate import configs from discovered resources
- ✅ Understand provider-defined imperative operations
- ✅ Know when to use Actions vs provisioners
- ✅ Ready for Terraform 1.14 advanced features

> **⚠️ Provider Support Required**: Both list resources and actions require explicit provider support. Not all providers implement these features yet. Check provider documentation for availability.

---

### Supplemental Topics (Added Post-Release)

The following topics were added to existing courses after the initial release:

| Course | Topic | Location | Description |
|--------|-------|----------|-------------|
| TF-101 | `terraform_data` vs `null_resource` | `TF-101-intro-basics/terraform-data/` | Modern replacement for null_resource (1.4+) |
| TF-101 | `local-exec` provisioner | `TF-101-intro-basics/terraform-data/` | When to use and anti-patterns |
| TF-102 | `for` expressions | `TF-102-variables-loops/5-for-expressions/` | List/map comprehensions with filtering |
| TF-104 | `terraform console` | `TF-104-state-cli/terraform-console/` | Interactive REPL for testing functions |
| TF-201 | `moved` blocks | `TF-201-module-design/moved-blocks/` | Rename/move resources without state CLI (1.1+) |
| TF-203 | JSON-driven config | `TF-203-yaml-config/json-config/` | `jsondecode()` and `jsonencode()` patterns |
| TF-204 | `removed` blocks | `TF-204-import-migration/removed-blocks/` | Stop managing resources without destroying (1.7+) |
| TF-204 | Identity-based import | `TF-204-import-migration/3-identity-import/` | `identity` attribute in import blocks (1.12+) |
| TF-301 | Sensitive values | `TF-301-validation/3-sensitive-values/` | `sensitive` attribute and `nonsensitive()` |
| TF-301 | Ephemeral values | `TF-301-validation/4-ephemeral-values/` | `ephemeral` variables/outputs, `ephemeralasnull()` (1.10+) |
| TF-301 | Cross-variable validation | `TF-301-validation/1-variable-conditions/` | Validation rules referencing other variables (1.9+) |
| TF-302 | Lifecycle meta-arguments | `TF-302-conditions-checks/3-lifecycle-arguments/` | `create_before_destroy`, `prevent_destroy`, `ignore_changes`, `replace_triggered_by` |
| TF-302 | Write-only attributes | `TF-302-conditions-checks/4-write-only-attributes/` | Provider-defined attributes never stored in state (1.11+) |
| TF-303 | JUnit XML output | `TF-303-test-framework/` | `-junit-xml` flag for CI/CD integration (1.11+) |
| TF-303 | Parallel test execution | `TF-303-test-framework/` | `-parallelism=n` flag (1.12+) |
| TF-303 | Override during plan | `TF-303-test-framework/` | `override_during = plan` for unit testing (1.11+) |
| TF-305 | S3 native state locking | `TF-305-workspaces-remote-state/2-remote-backends/` | `use_lockfile = true` replaces DynamoDB (1.11+) |
| TF-306 | `templatestring` function | `TF-306-functions/1-string-functions/` | Render templates from string values (1.9+) |
| TF-306 | `ephemeralasnull` function | `TF-306-functions/` | Convert ephemeral values to null (1.10+) |
| TF-306 | `element()` negative indices | `TF-306-functions/2-collection-functions/` | `element(list, -1)` for last element (1.10+) |
| PKR-102 | Post-processors | `PKR-102-qemu-provisioners/post-processors/` | `shell-local` and `manifest` post-processors |
| PKR-103 | Packer variables | `PKR-103-ansible/packer-variables/` | Variable blocks, `.pkrvars.hcl`, locals, sensitive |

---

### PKR-100 Series: Packer Fundamentals (4 hours)

#### PKR-101: Introduction to Image Building
**Duration**: 1 hour  
**Level**: Beginner  
**Prerequisites**: TF-101 (recommended)  
**Location**: `PKR-100-fundamentals/PKR-101-intro/`

**Description**:
Learn the fundamentals of image building with Packer. Understand why golden images are important and how Packer automates image creation for consistent, repeatable infrastructure.

**Learning Objectives**:
- Understand what Packer is and why use it
- Learn golden image concepts
- Understand Packer vs configuration management
- Learn Packer workflow
- Create your first image
- Understand builders, provisioners, and communicators

**Topics Covered**:
- What is Packer?
- Golden image benefits
- Packer architecture
- Builders (QEMU for Libvirt)
- Provisioners
- Communicators
- Image workflow

**Hands-On Exercises**:
- Install Packer
- Create basic Ubuntu image
- Run Packer build
- Test image with Terraform
- Understand build process

**Key Takeaways**:
- ✅ Understand image building concepts
- ✅ Know when to use Packer
- ✅ Can create basic images
- ✅ Understand Packer workflow
- ✅ Ready for advanced image building

---

#### PKR-102: QEMU Builder & Provisioners
**Duration**: 1 hour  
**Level**: Beginner  
**Prerequisites**: PKR-101  
**Location**: `PKR-100-fundamentals/PKR-102-qemu-provisioners/`

**Description**:
Master the QEMU builder for creating Libvirt-compatible images. Learn how to use shell and PowerShell provisioners to configure images during the build process.

**Learning Objectives**:
- Configure QEMU builder
- Use shell provisioners
- Use PowerShell provisioners
- Optimize image builds
- Handle build failures
- Create Linux and Windows images

**Topics Covered**:
- QEMU builder configuration
- Shell provisioner
- PowerShell provisioner
- File provisioner
- Build optimization
- Error handling
- Image testing

**Hands-On Exercises**:
- Build Linux image with shell scripts
- Build Windows image with PowerShell
- Optimize build time
- Handle provisioner failures
- Test images

**Key Takeaways**:
- ✅ Can configure QEMU builder
- ✅ Can use provisioners effectively
- ✅ Can build Linux and Windows images
- ✅ Know optimization techniques
- ✅ Can troubleshoot builds

---

#### PKR-103: Ansible Configuration Management
**Duration**: 1.5 hours  
**Level**: Intermediate  
**Prerequisites**: PKR-102  
**Location**: `PKR-100-fundamentals/PKR-103-ansible/`

**Description**:
Use Ansible with Packer for sophisticated image configuration. Learn how to integrate Ansible playbooks into your image builds for complex configuration management.

**Learning Objectives**:
- Configure Ansible provisioner
- Write Ansible playbooks for images
- Manage dependencies
- Handle secrets securely
- Test Ansible configurations
- Choose between shell and Ansible

**Topics Covered**:
- Ansible provisioner setup
- Playbook integration
- Role usage
- Dependency management
- Secret handling
- Testing strategies
- When to use Ansible vs shell

**Hands-On Exercises**:
- Create basic Ansible playbook
- Build image with Ansible
- Use Ansible roles
- Handle secrets
- Test configurations

**Key Takeaways**:
- ✅ Can use Ansible with Packer
- ✅ Can write playbooks for images
- ✅ Know when to use Ansible
- ✅ Can handle secrets securely
- ✅ Can build complex images

---

#### PKR-104: Image Versioning & HCP Packer
**Duration**: 0.5 hours  
**Level**: Intermediate  
**Prerequisites**: PKR-103  
**Location**: `PKR-100-fundamentals/PKR-104-versioning-hcp/`

**Description**:
Manage image versions and integrate with HCP Packer. Learn how to version images, track them across environments, and use HCP Packer for image management.

**Learning Objectives**:
- Version images semantically
- Track images across environments
- Use HCP Packer
- Manage image lifecycle
- Implement image promotion
- Integrate with Terraform

**Topics Covered**:
- Image versioning strategies
- HCP Packer setup
- Image tracking
- Version promotion
- Terraform integration
- Image lifecycle management

**Hands-On Exercises**:
- Version images
- Set up HCP Packer
- Track images
- Promote versions
- Use versioned images in Terraform

**Key Takeaways**:
- ✅ Can version images properly
- ✅ Can use HCP Packer
- ✅ Can track images
- ✅ Can integrate with Terraform
- ✅ Ready for production image management

---

## ☁️ Cloud Provider Modules (Optional)

### AWS-200 Series: AWS Terraform (Optional)

#### AWS-201: AWS Setup & Authentication
**Duration**: 0.5 hours  
**Prerequisites**: TF-100 series  
**Location**: `cloud-modules/AWS-200-terraform/AWS-201-setup/`

**Description**:
Set up AWS credentials and understand AWS-specific Terraform concepts. Learn how to authenticate, configure the AWS provider, and understand AWS resource naming.

**Topics Covered**:
- AWS account setup
- IAM user creation
- Access key management
- AWS CLI configuration
- Provider configuration
- Region selection

---

#### AWS-202: AWS Compute (EC2)
**Duration**: 2 hours  
**Prerequisites**: AWS-201, TF-103  
**Location**: `cloud-modules/AWS-200-terraform/AWS-202-compute/`

**Description**:
Apply your Libvirt VM knowledge to AWS EC2. Learn how concepts translate from Libvirt to AWS and understand AWS-specific features.

**Concept Mapping**:
- libvirt_domain → aws_instance
- libvirt_volume → aws_ebs_volume
- Cloud-init → User data

**Topics Covered**:
- EC2 instance creation
- AMI selection
- Instance types
- User data
- EBS volumes
- Instance lifecycle

---

#### AWS-203: AWS Networking (VPC)
**Duration**: 2 hours  
**Prerequisites**: AWS-202, TF-103  
**Location**: `cloud-modules/AWS-200-terraform/AWS-203-networking/`

**Description**:
Apply your Libvirt networking knowledge to AWS VPC. Learn how networking concepts translate and understand AWS-specific networking features.

**Concept Mapping**:
- libvirt_network → aws_vpc
- Network modes → Subnets (public/private)
- DHCP → VPC DHCP options

**Topics Covered**:
- VPC creation
- Subnet design
- Internet Gateway
- NAT Gateway
- Route tables
- Network ACLs

---

### AZ-200 Series: Azure Terraform (Optional)

#### AZ-201: Azure Setup & Authentication
**Duration**: 0.5 hours  
**Prerequisites**: TF-100 series  
**Location**: `cloud-modules/AZ-200-terraform/AZ-201-setup/`

**Description**:
Set up Azure credentials and understand Azure-specific Terraform concepts. Learn authentication methods, provider configuration, and Azure resource organization.

**Topics Covered**:
- Azure account setup
- Service principal creation
- Azure CLI configuration
- Provider configuration
- Resource group concepts
- Region selection

---

#### AZ-202: Azure Compute (VMs)
**Duration**: 2 hours  
**Prerequisites**: AZ-201, TF-103  
**Location**: `cloud-modules/AZ-200-terraform/AZ-202-compute/`

**Description**:
Apply your Libvirt VM knowledge to Azure VMs. Learn how concepts translate from Libvirt to Azure and understand Azure-specific features.

**Concept Mapping**:
- libvirt_domain → azurerm_linux_virtual_machine
- libvirt_volume → azurerm_managed_disk
- Cloud-init → Custom data

**Topics Covered**:
- VM creation
- Image selection
- VM sizes
- Custom data
- Managed disks
- VM lifecycle

---

#### AZ-203: Azure Networking (VNet)
**Duration**: 2 hours  
**Prerequisites**: AZ-202, TF-103  
**Location**: `cloud-modules/AZ-200-terraform/AZ-203-networking/`

**Description**:
Apply your Libvirt networking knowledge to Azure VNet. Learn how networking concepts translate and understand Azure-specific networking features.

**Concept Mapping**:
- libvirt_network → azurerm_virtual_network
- Network modes → Subnets
- Security → Network Security Groups

**Topics Covered**:
- VNet creation
- Subnet design
- NSG configuration
- Public IPs
- Load balancers
- VNet peering

---

### MC-300 Series: Multi-Cloud Patterns (Optional)

#### MC-301: Multi-Cloud Strategy
**Duration**: 1 hour  
**Prerequisites**: At least one cloud module  
**Location**: `cloud-modules/MC-300-multi-cloud/MC-301-strategy/`

**Description**:
Learn strategies for managing infrastructure across multiple cloud providers. Understand when multi-cloud makes sense and how to implement it effectively.

**Topics Covered**:
- Multi-cloud vs hybrid cloud
- When to use multi-cloud
- Abstraction strategies
- Provider-agnostic modules
- Cost considerations
- Complexity management

---

## 📊 Course Statistics

### Core Training
- **Total Courses**: 18 courses (+ TF-307 Query & Actions, TF-405 Stacks)
- **Total Duration**: 27 hours (core) + 5 hours (TF-400 expert)
- **Hands-On Exercises**: 65+ exercises
- **Prerequisites**: None (start from TF-101)

### Cloud Modules (Optional)
- **AWS Courses**: 7 courses
- **Azure Courses**: 7 courses
- **Multi-Cloud Courses**: 4 courses
- **Additional Duration**: 15-20 hours

---

## 🎯 Recommended Learning Paths

### Path 1: Core Training Only (27 hours)
Perfect for learning IaC without cloud costs:
1. TF-100 series (6h)
2. TF-200 series (6h)
3. TF-300 series (8h, includes TF-307)
4. PKR-100 series (4h)
5. TF-400 series (5h, includes TF-405) — optional expert level

### Path 2: Core + AWS (42 hours)
Core training plus AWS specialization:
1. Core Training (27h)
2. AWS-200 series (15h)

### Path 3: Core + Azure (42 hours)
Core training plus Azure specialization:
1. Core Training (27h)
2. AZ-200 series (15h)

### Path 4: Complete Training (55+ hours)
Everything including multi-cloud:
1. Core Training (27h)
2. AWS-200 series (15h)
3. AZ-200 series (15h)
4. MC-300 series (5h)

---

## 🏆 Expert Training Courses

### TF-400 Series: HCP Terraform & Enterprise Features (6 hours)

**Prerequisites**: TF-300 (all courses), TF-305 (Workspaces & Remote State)
**Location**: `TF-400-hcp-enterprise/`
**Cost**: Free tier available (Sentinel requires Plus/Enterprise)

**Description**:
Expert-level course covering HCP Terraform (formerly Terraform Cloud) — HashiCorp's managed platform for team-based Terraform workflows. Learn to move from solo local Terraform to a collaborative, policy-enforced, enterprise-grade infrastructure workflow.

---

#### TF-401: HCP Terraform Fundamentals
**Duration**: 1.5 hours
**Level**: Expert
**Prerequisites**: TF-305
**Location**: `TF-400-hcp-enterprise/TF-401-hcp-fundamentals/`

**Description**:
Introduction to HCP Terraform. Covers the platform architecture, workspace types, authentication, and migrating existing local state to HCP Terraform.

**Learning Objectives**:
- Explain what HCP Terraform is and how it differs from local Terraform
- Describe HCP Terraform vs Terraform Enterprise (self-hosted)
- Set up an HCP Terraform organization and workspace
- Authenticate using `terraform login` and API tokens
- Understand VCS-driven, CLI-driven, and API-driven workspace types
- Migrate existing local state to HCP Terraform

**Topics Covered**:
- HCP Terraform architecture and run lifecycle
- Free tier vs paid tiers comparison
- The `cloud` block (replaces `backend` block)
- Workspace types and when to use each
- State migration with `terraform init`

**Hands-On**:
- Set up first HCP Terraform workspace
- Authenticate with `terraform login`
- Run `terraform plan` remotely
- Migrate local state to HCP Terraform

---

#### TF-402: Remote Runs & VCS Integration
**Duration**: 1.5 hours
**Level**: Expert
**Prerequisites**: TF-401
**Location**: `TF-400-hcp-enterprise/TF-402-remote-runs/`

**Description**:
Deep dive into HCP Terraform's remote execution model and VCS integration. Learn to configure GitOps workflows where pull requests trigger speculative plans and merges trigger applies.

**Learning Objectives**:
- Configure a VCS-driven workspace connected to GitHub
- Understand speculative plans on pull requests
- Configure run triggers for workspace-to-workspace dependencies
- Use workspace variables and variable sets effectively

**Topics Covered**:
- Remote run lifecycle (plan → policy check → apply)
- VCS-driven workspace configuration
- Speculative plans on PRs
- Run triggers (workspace dependencies)
- Workspace variables vs variable sets
- Auto-apply vs manual approval

**Hands-On**:
- Connect workspace to GitHub repository
- Open a PR and observe speculative plan comment
- Configure run trigger between two workspaces
- Create a variable set for shared configuration

---

#### TF-403: Security & Access Control
**Duration**: 1 hour
**Level**: Expert
**Prerequisites**: TF-402
**Location**: `TF-400-hcp-enterprise/TF-403-security-access/`

**Description**:
Configure teams, permissions, and secure credential management in HCP Terraform. Learn to implement dynamic provider credentials using OIDC — eliminating long-lived secrets entirely.

**Learning Objectives**:
- Configure teams and RBAC in HCP Terraform
- Understand organization-level vs workspace-level permissions
- Implement variable sets for shared secrets
- Configure dynamic provider credentials (OIDC)

**Topics Covered**:
- Teams and permission levels (read/plan/write/admin)
- Organization-level vs workspace-level access
- Variable sets for shared credentials
- Dynamic credentials via OIDC (no long-lived secrets)
- Audit logging (Plus/Enterprise)
- Managing HCP Terraform with the `tfe` provider

**Hands-On**:
- Create teams with different permission levels
- Configure variable sets for shared configuration
- Review OIDC dynamic credentials setup

---

#### TF-404: Sentinel Policy as Code (Enterprise)
**Duration**: 1 hour
**Level**: Expert
**Prerequisites**: TF-403, TF-304 (recommended)
**Location**: `TF-400-hcp-enterprise/TF-404-sentinel-policies/`
**Note**: Requires HCP Terraform Plus/Business or Terraform Enterprise

**Description**:
Learn HashiCorp's Sentinel policy-as-code framework. Write policies that gate Terraform deployments between plan and apply, enforcing organizational standards automatically.

**Learning Objectives**:
- Explain Sentinel and its three enforcement levels
- Compare Sentinel vs OPA/Rego — when to use each
- Write Sentinel policies using the `tfplan/v2` import
- Test policies locally with mock data
- Configure policy sets in HCP Terraform

**Topics Covered**:
- Sentinel enforcement levels: advisory, soft-mandatory, hard-mandatory
- Sentinel imports: `tfplan/v2`, `tfconfig/v2`, `tfstate/v2`, `tfrun`
- Policy structure and syntax
- Mock data for local testing
- Policy sets and VCS-connected policies
- Sentinel vs OPA/Rego comparison

**Hands-On**:
- Write a policy to restrict VM memory in non-production workspaces
- Create mock test data for pass and fail cases
- Test policy locally with `sentinel test`
- Configure a policy set in HCP Terraform

---

#### TF-405: Terraform Stacks (NEW — 1.13)
**Duration**: 1 hour
**Level**: Expert
**Prerequisites**: TF-401, TF-402
**Location**: `TF-400-hcp-enterprise/TF-405-stacks/`
**Terraform Version**: 1.13+
**Note**: Requires HCP Terraform — not available in local/OSS Terraform

**Description**:
Explore Terraform Stacks — a new architectural paradigm for orchestrating multiple Terraform configurations as a single deployable unit. Stacks solve the "many workspaces" problem by providing a first-class way to deploy the same configuration across multiple environments, regions, or accounts with coordinated lifecycle management.

**Learning Objectives**:
- Explain what Terraform Stacks are and when to use them
- Understand the difference between Stacks, Workspaces, and separate configurations
- Describe the `.tfstack.hcl` and `.tfdeploy.hcl` file formats
- Understand Components (like modules) and Deployments (like workspaces)
- Use the `terraform stacks` CLI command
- Know the limitations and HCP Terraform requirements

**Topics Covered**:
1. **What are Stacks?**
   - Problem: managing many similar workspaces
   - Stacks as a unit of deployment
   - Components vs Deployments
   - Stacks vs Workspaces vs separate configs

2. **Stack File Formats**
   - `.tfstack.hcl` — component definitions and provider configuration
   - `.tfdeploy.hcl` — deployment definitions (environments/regions)
   - `component` block syntax
   - `deployment` block syntax

3. **terraform stacks CLI**
   - `terraform stacks init`
   - `terraform stacks plan`
   - `terraform stacks apply`
   - Stack-specific state management

4. **When to Use Stacks**
   - Multi-region deployments
   - Multi-account deployments
   - Environment promotion (dev → staging → prod)
   - Limitations and trade-offs

**Hands-On Exercises** (Conceptual — requires HCP Terraform):
- Design a Stack for a multi-environment deployment
- Write a `.tfstack.hcl` component definition
- Write a `.tfdeploy.hcl` deployment configuration
- Compare Stack approach vs workspace approach for the same scenario

**Key Takeaways**:
- ✅ Understand the Stacks paradigm and use cases
- ✅ Know `.tfstack.hcl` and `.tfdeploy.hcl` file formats
- ✅ Can design a Stack architecture for multi-environment deployments
- ✅ Understand when Stacks are better than workspaces
- ✅ Know the HCP Terraform requirements and limitations

> **⚠️ HCP Terraform Required**: Terraform Stacks require HCP Terraform (free tier available). They cannot be used with local Terraform or self-managed backends. The `terraform stacks` command is only available when connected to HCP Terraform.

---

## 📚 Additional Resources

- **Quick Start**: See `quick-start-guide.md`
- **Learning Progression**: See `learning-progression.md`
- **Directory Structure**: See `directory-structure.md`
- **Choosing Your Path**: See `choosing-your-path.md`

---

**Ready to start?** Begin with [Quick Start Guide](quick-start-guide.md)!