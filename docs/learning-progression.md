# Learning Progression Guide

**Purpose**: This document outlines the recommended learning progression through the Hashi-Training course, explaining how concepts build upon each other.

---

## 🎯 Overview

The training is designed as a progressive journey where each course builds on previous knowledge. This guide explains:
- What you'll learn in each phase
- Why the order matters
- Prerequisites for each course
- How concepts connect

---

## 📊 Learning Architecture

```
Foundation Layer (Core Training - 21 hours)
├── TF-100: Terraform Fundamentals (6 hours)
│   ├── TF-101: Introduction to IaC & Terraform Basics (1.5h)
│   ├── TF-102: Variables, Loops & Functions (1.5h)
│   ├── TF-103: Infrastructure Resources (2h)
│   └── TF-104: State Management & CLI (1h)
│
├── TF-200: Terraform Modules & Patterns (6 hours)
│   ├── TF-201: Module Design & Composition (1.5h)
│   ├── TF-202: Advanced Module Patterns (1.5h)
│   ├── TF-203: YAML-Driven Configuration (1.5h)
│   └── TF-204: Import & Migration Strategies (1.5h)
│
├── TF-300: Testing, Validation & Policy (6.5 hours)
│   ├── TF-301: Input Validation & Advanced Functions (1.5h)
│   ├── TF-302: Pre/Post Conditions & Check Blocks (1.5h)
│   ├── TF-303: Terraform Test Framework (1h) [planned]
│   ├── TF-304: Policy as Code (1h) [planned]
│   ├── TF-305: Workspaces & Remote State (1.5h)
│   └── TF-306: Terraform Functions Deep Dive (1.5h)
│
├── TF-400: HCP Terraform & Enterprise Features (5 hours) [EXPERT]
│   ├── TF-401: HCP Terraform Fundamentals (1.5h)
│   ├── TF-402: Remote Runs & VCS Integration (1.5h)
│   ├── TF-403: Security & Access Control (1h)
│   └── TF-404: Sentinel Policy as Code (1h)
│
└── PKR-100: Packer Fundamentals (4 hours)
    ├── PKR-101: Introduction to Image Building (1h)
    ├── PKR-102: QEMU Builder & Provisioners (1h)
    ├── PKR-103: Ansible Configuration Management (1.5h)
    └── PKR-104: Image Versioning & HCP Packer (0.5h)

Application Layer (Cloud Modules - Optional)
├── AWS-200: AWS Terraform
├── AZ-200: Azure Terraform
└── MC-300: Multi-Cloud Patterns
```

---

## 🏗️ Phase 1: TF-100 - Terraform Fundamentals

### TF-101: Introduction to IaC & Terraform Basics (1.5 hours)
**Location**: `TF-100-fundamentals/TF-101-intro-basics/`

#### What You'll Learn
1. **Infrastructure as Code Concepts** - What IaC is and why it matters
2. **Terraform Basics** - How Terraform works (plan → apply → state)
3. **Providers** - How Terraform connects to infrastructure platforms
4. **Basic Resources** - Creating your first infrastructure
5. **HCL Syntax** - Terraform's configuration language

#### Why Start Here?
- Foundation for everything else
- Introduces core concepts
- Hands-on from the start
- Builds confidence

#### Key Concepts Mastered
- ✅ What Infrastructure as Code means
- ✅ How Terraform works (declarative approach)
- ✅ Basic HCL syntax
- ✅ Provider configuration
- ✅ Resource creation

#### Hands-On Practice
- Create local files with `local_file` provider
- Introduce Libvirt provider
- First `terraform init`, `plan`, `apply`
- Understand the workflow

---

### TF-102: Variables, Loops & Functions (1.5 hours)
**Location**: `TF-100-fundamentals/TF-102-variables-loops/`

#### What You'll Learn
1. **Variables** - Making configurations reusable
2. **Loops** - Creating multiple resources efficiently
3. **Environment Variables** - Managing configuration
4. **Functions** - Built-in functions for data manipulation

#### Why After TF-101?
- Requires understanding of resources
- Makes examples more realistic
- Introduces DRY principles
- Prepares for complex scenarios

#### Key Concepts Mastered
- ✅ Variable types and validation
- ✅ For loops and count
- ✅ Environment variable usage
- ✅ Common Terraform functions
- ✅ Dynamic configuration

#### Hands-On Practice
- Use variables to customize resources
- Loop through lists to create multiple resources
- Read from environment variables
- Apply functions to transform data

---

### TF-103: Infrastructure Resources (2 hours)
**Location**: `TF-100-fundamentals/TF-103-infrastructure/`

#### What You'll Learn
1. **Networks** - Creating virtual networks with Libvirt
2. **Security** - Network isolation and firewall concepts
3. **Virtual Machines** - Creating and managing VMs
4. **Dependencies** - How resources depend on each other
5. **Cross-Resource References** - Connecting resources

#### Why After TF-102?
- Requires understanding of variables
- Uses loops for multiple VMs
- Demonstrates state with complex resources
- Real infrastructure examples

#### Key Concepts Mastered
- ✅ Network creation and configuration
- ✅ VM lifecycle management
- ✅ Resource dependencies
- ✅ Data sources
- ✅ Outputs for resource information

#### Hands-On Practice
- Create virtual networks
- Configure DHCP and DNS
- Launch VMs with cloud-init
- Connect VMs to networks
- Manage VM lifecycle

#### Real-World Connection
These concepts directly translate to:
- **AWS**: VPC, EC2, Security Groups
- **Azure**: VNet, VMs, NSGs
- **Any cloud provider's networking and compute**

---

### TF-104: State Management & CLI (1 hour)
**Location**: `TF-100-fundamentals/TF-104-state-cli/`

#### What You'll Learn
1. **CLI Commands** - Essential Terraform commands
2. **State Management** - Understanding Terraform state
3. **Module Basics** - Introduction to modules
4. **Debugging** - Troubleshooting Terraform issues

#### Why After TF-103?
- State makes more sense after complex resources
- Debugging requires experience with errors
- Module intro prepares for TF-200
- Ties together all TF-100 concepts

#### Key Concepts Mastered
- ✅ Terraform CLI mastery
- ✅ State file understanding
- ✅ Module creation basics
- ✅ Debugging techniques
- ✅ Error interpretation

#### Hands-On Practice
- Use all major CLI commands
- Inspect and manage state
- Create first simple module
- Debug common errors
- Use terraform console

---

## 🚀 Phase 2: TF-200 - Terraform Modules & Patterns

### Prerequisites
- ✅ Complete TF-100 series
- ✅ Comfortable with basic modules
- ✅ Understanding of resource dependencies

### TF-201: Module Design & Composition (1.5 hours)
**Location**: `TF-200-modules/TF-201-module-design/`

#### What You'll Learn
- Advanced module design patterns
- Module composition (modules calling modules)
- Optional attributes and dynamic blocks
- Module versioning strategies

#### Why After TF-100?
- Builds directly on TF-104 module intro
- Requires solid Terraform fundamentals
- Demonstrates real-world module patterns

---

### TF-202: Advanced Module Patterns (1.5 hours)
**Location**: `TF-200-modules/TF-202-advanced-patterns/`

#### What You'll Learn
- Private module registry (HCP Terraform)
- Canary and blue-green deployments
- Module versioning and publishing
- Team collaboration patterns

#### Why After TF-201?
- Requires understanding of module design
- Builds on composition concepts
- Introduces enterprise patterns

---

### TF-203: YAML-Driven Configuration (1.5 hours)
**Location**: `TF-200-modules/TF-203-yaml-config/`

#### What You'll Learn
- Using YAML for input data
- Dynamic resource creation from YAML
- Configuration validation
- When to use YAML vs HCL

#### Why After TF-202?
- Advanced technique for complex scenarios
- Requires solid module understanding
- Demonstrates data-driven infrastructure

---

### TF-204: Import & Migration Strategies (1.5 hours)
**Location**: `TF-200-modules/TF-204-import-migration/`

#### What You'll Learn
- Importing existing infrastructure
- Generating configuration from imports
- Migration strategies
- State management for imports

#### Why Last in TF-200?
- Ties together all TF-200 concepts
- Real-world migration scenarios
- Prepares for production work

---

## 🧪 Phase 3: TF-300 - Testing, Validation & Policy

### Prerequisites
- ✅ Complete TF-200 series
- ✅ Experience with modules
- ✅ Understanding of Terraform workflow

### TF-301: Input Validation & Advanced Functions (1.5 hours)
**Location**: `TF-300-advanced/TF-301-validation/`

#### What You'll Learn
- Variable validation (Terraform 1.14+)
- Cross-variable validation
- Advanced function usage
- Provider-defined functions (Azure)

#### Why Start TF-300 Here?
- Validation prevents errors early
- Foundation for testing
- Introduces quality assurance concepts

---

### TF-302: Pre/Post Conditions & Check Blocks (1.5 hours)
**Location**: `TF-300-advanced/TF-302-conditions-checks/`

#### What You'll Learn
- Preconditions (before resource operations)
- Postconditions (after resource operations)
- Check blocks (final validation)
- When to use each validation type

#### Why After TF-301?
- Builds on validation concepts
- Adds runtime validation
- Completes validation strategy

---

### TF-303: Terraform Test Framework (1 hour) [PLANNED]
**Location**: `TF-300-advanced/TF-303-test-framework/`

#### What You'll Learn
- Writing Terraform tests
- Test organization
- Mock providers
- CI/CD integration

---

### TF-304: Policy as Code (1 hour) [PLANNED]
**Location**: `TF-300-advanced/TF-304-policy-code/`

#### What You'll Learn
- OPA/Rego policies
- Policy testing
- Enforcement levels
- Compliance automation

---

## 🖼️ Phase 4: PKR-100 - Packer Fundamentals

### Prerequisites
- ✅ Complete TF-101 (minimum)
- ✅ Understanding of VMs
- ✅ Basic Linux/shell knowledge

### PKR-101: Introduction to Image Building (1 hour)
**Location**: `PKR-100-fundamentals/PKR-101-intro/`

#### What You'll Learn
- What Packer is and why use it
- Golden image concepts
- Packer vs configuration management
- Image building workflow

---

### PKR-102: QEMU Builder & Provisioners (1 hour)
**Location**: `PKR-100-fundamentals/PKR-102-qemu-provisioners/`

#### What You'll Learn
- Building images for Libvirt
- QEMU builder configuration
- Shell and PowerShell provisioners
- Image optimization

---

### PKR-103: Ansible Configuration Management (1.5 hours)
**Location**: `PKR-100-fundamentals/PKR-103-ansible/`

#### What You'll Learn
- Ansible provisioner
- Playbook integration
- Configuration management patterns
- Testing images

---

### PKR-104: Image Versioning & HCP Packer (0.5 hours)
**Location**: `PKR-100-fundamentals/PKR-104-versioning-hcp/`

#### What You'll Learn
- Image versioning strategies
- HCP Packer integration
- Image distribution
- Version management

#### Why After Terraform?
- Terraform creates infrastructure
- Packer creates the images Terraform uses
- Understanding VMs helps with image building
- Can test Packer images with Terraform

#### Integration with Terraform
```
Packer builds image → Terraform uses image → Infrastructure deployed
```

---

## ☁️ Phase 5: Cloud Provider Modules (Optional)

### Prerequisites
- ✅ Complete all core training
- ✅ Cloud provider account
- ✅ Budget for cloud resources

### AWS-200 Module (Optional)
**Location**: `cloud-modules/AWS-200-terraform/`

#### Concept Mapping
| Core (Libvirt) | AWS Equivalent |
|----------------|----------------|
| libvirt_domain | aws_instance |
| libvirt_network | aws_vpc |
| libvirt_volume | aws_ebs_volume |

---

### AZ-200 Module (Optional)
**Location**: `cloud-modules/AZ-200-terraform/`

#### Concept Mapping
| Core (Libvirt) | Azure Equivalent |
|----------------|------------------|
| libvirt_domain | azurerm_linux_virtual_machine |
| libvirt_network | azurerm_virtual_network |
| libvirt_volume | azurerm_managed_disk |

---

### MC-300 Multi-Cloud Module (Optional)
**Location**: `cloud-modules/MC-300-multi-cloud/`

#### Prerequisites
- ✅ Complete at least one cloud module
- ✅ Understanding of both AWS and Azure

---

## 🎓 Skill Progression

### After TF-100
**You Can**:
- ✅ Write basic Terraform configurations
- ✅ Create and manage infrastructure locally
- ✅ Use variables and loops
- ✅ Create simple modules
- ✅ Debug common issues

**You Cannot Yet**:
- ❌ Design complex module architectures
- ❌ Implement advanced deployment patterns
- ❌ Write comprehensive tests
- ❌ Enforce policies

---

### After TF-200
**You Can**:
- ✅ Design complex module architectures
- ✅ Publish and version modules
- ✅ Implement deployment patterns
- ✅ Use data-driven configuration
- ✅ Migrate existing infrastructure

**You Cannot Yet**:
- ❌ Write comprehensive tests
- ❌ Implement validation strategies
- ❌ Enforce organizational policies

---

### After TF-300
**You Can**:
- ✅ Write comprehensive tests
- ✅ Implement validation at all levels
- ✅ Enforce policies
- ✅ Ensure compliance
- ✅ Build production-grade infrastructure

**You're Ready For**:
- ✅ Production deployments
- ✅ Team collaboration
- ✅ Enterprise environments
- ✅ Cloud certifications
- ✅ TF-400: HCP Terraform & Enterprise Features

---

## 🏆 Phase 4: TF-400 - HCP Terraform & Enterprise Features

**Prerequisites**: TF-300 (all), TF-305 (Workspaces & Remote State)
**Duration**: 5 hours
**Level**: Expert

This phase takes you from individual Terraform practitioner to enterprise-grade team workflows. You'll learn to use HCP Terraform (HashiCorp's managed platform) for collaborative infrastructure management with policy enforcement.

### TF-401: HCP Terraform Fundamentals (1.5 hours)
**Location**: `TF-400-hcp-enterprise/TF-401-hcp-fundamentals/`

**Concepts Introduced**:
- HCP Terraform as a managed platform for team Terraform workflows
- The `cloud` block replacing the `backend` block
- Workspace types: VCS-driven, CLI-driven, API-driven
- Remote state storage and remote execution
- Migrating local state to HCP Terraform

**Why This Order?**
TF-305 taught you about remote backends and state sharing. TF-401 builds directly on that — HCP Terraform is the managed version of what you configured manually in TF-305.

### TF-402: Remote Runs & VCS Integration (1.5 hours)
**Location**: `TF-400-hcp-enterprise/TF-402-remote-runs/`

**Concepts Introduced**:
- VCS-driven GitOps: PRs trigger plans, merges trigger applies
- Speculative plans on pull requests
- Run triggers for workspace-to-workspace dependencies
- Variable sets for shared configuration

**Builds On**:
- TF-305 (remote state sharing between workspaces)
- TF-204 (import/migration — now applied to workspace migration)

### TF-403: Security & Access Control (1 hour)
**Location**: `TF-400-hcp-enterprise/TF-403-security-access/`

**Concepts Introduced**:
- Teams and RBAC in HCP Terraform
- Dynamic provider credentials via OIDC (no long-lived secrets)
- Variable sets for shared secrets
- Audit logging (Plus/Enterprise)
- Meta-Terraform: managing HCP Terraform with the `tfe` provider

**Builds On**:
- TF-301 (sensitive variables — now applied at platform level)
- TF-402 (workspaces and variable sets)

### TF-404: Sentinel Policy as Code (1 hour)
**Location**: `TF-400-hcp-enterprise/TF-404-sentinel-policies/`

**Concepts Introduced**:
- Sentinel as HashiCorp's native policy-as-code framework
- Enforcement levels: advisory, soft-mandatory, hard-mandatory
- Sentinel imports: `tfplan/v2`, `tfconfig/v2`, `tfstate/v2`, `tfrun`
- Policy sets and VCS-connected policies
- Mock data for local policy testing

**Builds On**:
- TF-304 (OPA/Rego policy concepts — Sentinel is the HCP Terraform-native alternative)
- TF-302 (conditions and checks — Sentinel extends this to organizational gates)

### After TF-400
**You Can**:
- ✅ Manage team Terraform workflows with HCP Terraform
- ✅ Implement GitOps with VCS-driven workspaces
- ✅ Enforce organizational policies with Sentinel
- ✅ Eliminate long-lived credentials with OIDC
- ✅ Manage HCP Terraform itself as code (meta-Terraform)

**You're Ready For**:
- ✅ Senior/Staff infrastructure engineer roles
- ✅ Platform engineering positions
- ✅ HashiCorp certifications (Terraform Associate, Professional)
- ✅ Enterprise Terraform deployments

---

### After PKR-100
**You Can**:
- ✅ Build custom images
- ✅ Automate image creation
- ✅ Version and manage images
- ✅ Integrate images with Terraform

---

### After Cloud Modules
**You Can**:
- ✅ Deploy to production clouds
- ✅ Apply concepts to any provider
- ✅ Design multi-cloud architectures
- ✅ Optimize cloud costs

---

## 🔄 Learning Loops

### Concept Reinforcement

Each phase reinforces previous concepts:

**Variables** (introduced in TF-102):
- Used in: Every subsequent course
- Advanced in: TF-201 (optional attributes)
- Validated in: TF-301 (conditions)

**Modules** (introduced in TF-104):
- Used in: TF-200, TF-300
- Advanced in: TF-201 (composition)
- Tested in: TF-303 (test framework)

**State** (introduced in TF-101):
- Used in: Every course
- Advanced in: TF-204 (import blocks)
- Managed in: TF-300 (testing)

---

## 📈 Difficulty Progression

```
Difficulty Level
    ↑
    │                                    ┌─────────┐
    │                              ┌─────┤ TF-300  │
    │                        ┌─────┤     └─────────┘
    │                  ┌─────┤ TF-200
    │            ┌─────┤     └─────────┘
    │      ┌─────┤ TF-100
    │┌─────┤     └─────────┘
    ││Setup│
    │└─────┘
    └──────────────────────────────────────────────→
                    Time
```

---

## ⏱️ Time Investment

### Minimum Time (Fast Pace)
- Setup: 1 hour
- TF-100: 5 hours
- TF-200: 5 hours
- TF-300: 4 hours
- PKR-100: 3 hours
- **Total**: ~18 hours

### Recommended Time (Comfortable Pace)
- Setup: 2 hours
- TF-100: 6 hours
- TF-200: 6 hours
- TF-300: 5 hours
- PKR-100: 4 hours
- **Total**: ~23 hours

### Thorough Learning (Deep Dive)
- Setup: 3 hours
- TF-100: 8 hours
- TF-200: 8 hours
- TF-300: 7 hours
- PKR-100: 5 hours
- **Total**: ~31 hours

---

## 🎯 Checkpoints

### After Each Course, You Should Be Able To:

**TF-101**:
- [ ] Explain what IaC is
- [ ] Write a basic Terraform configuration
- [ ] Use providers effectively
- [ ] Understand Terraform workflow

**TF-102**:
- [ ] Use variables effectively
- [ ] Create loops for multiple resources
- [ ] Apply functions to data
- [ ] Read from environment variables

**TF-103**:
- [ ] Create virtual networks
- [ ] Launch and manage VMs
- [ ] Connect resources together
- [ ] Use data sources

**TF-104**:
- [ ] Use all major CLI commands
- [ ] Understand state management
- [ ] Create a simple module
- [ ] Debug Terraform issues

**TF-201**:
- [ ] Design module architectures
- [ ] Compose modules together
- [ ] Use dynamic blocks
- [ ] Version modules

**TF-202**:
- [ ] Publish modules to registry
- [ ] Implement deployment patterns
- [ ] Use module versioning
- [ ] Collaborate with teams

**TF-203**:
- [ ] Use YAML for configuration
- [ ] Create dynamic resources
- [ ] Validate YAML input
- [ ] Choose YAML vs HCL

**TF-204**:
- [ ] Import existing infrastructure
- [ ] Generate configuration
- [ ] Plan migrations
- [ ] Manage imported state

**TF-301**:
- [ ] Write validation rules
- [ ] Use advanced functions
- [ ] Validate cross-variable logic
- [ ] Use provider functions

**TF-302**:
- [ ] Implement preconditions
- [ ] Use postconditions
- [ ] Create check blocks
- [ ] Choose validation types

**PKR-101-104**:
- [ ] Build custom images
- [ ] Use provisioners
- [ ] Version images
- [ ] Integrate with Terraform

---

## 🚀 Next Steps

Once you've completed the progression:

1. **Practice**: Build personal projects
2. **Contribute**: Open-source Terraform modules
3. **Certify**: Pursue cloud certifications
4. **Specialize**: Deep dive into specific areas
5. **Share**: Teach others what you've learned

---

## 📚 Additional Resources

- **Terraform Documentation**: https://developer.hashicorp.com/terraform
- **Terraform Registry**: https://registry.terraform.io/
- **HashiCorp Learn**: https://learn.hashicorp.com/
- **Community Forums**: https://discuss.hashicorp.com/

---

**Ready to start your journey?** Begin with [Quick Start Guide](quick-start-guide.md)!