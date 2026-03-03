# Directory Structure Guide

**Purpose**: This document explains the organization of the hashi-training repository and how to navigate it effectively.

---

## 📂 Overview

The repository is organized into **core training** (Libvirt-based) and **optional cloud modules** (AWS/Azure/Multi-Cloud). This modular structure allows you to:

- Complete core training without cloud costs
- Choose which cloud providers to learn
- Add modules as your needs evolve

---

## 🏗️ Top-Level Structure

```
hashi-training/
├── docs/                      # All documentation
├── TF-100-fundamentals/       # Terraform fundamentals (6h)
├── TF-200-modules/            # Terraform modules (6h)
├── TF-300-advanced/           # Testing & validation (5h)
├── TF-400-hcp-enterprise/     # HCP Terraform & Enterprise (5h)
├── PKR-100-fundamentals/      # Packer training (4h)
├── cloud-modules/             # Optional cloud providers
│   ├── AWS-200-terraform/     # AWS module
│   ├── AZ-200-terraform/      # Azure module
│   └── MC-300-multi-cloud/    # Multi-cloud patterns
├── README.md                  # Main repository README
└── TODO.md                    # Project tracking
```

---

## 📚 Documentation Directory (`docs/`)

All guides and reference materials:

```
docs/
├── libvirt-setup.md           # Libvirt installation guide
├── quick-start-guide.md       # Getting started
├── choosing-your-path.md      # Path selection guide
├── learning-progression.md    # How concepts build
├── directory-structure.md     # This file
├── course-catalog.md          # Complete course descriptions
├── base-image-preparation.md  # Image preparation guide
├── faq.md                     # Frequently asked questions
├── troubleshooting.md         # Common issues
└── glossary.md                # Terminology reference
```

### When to Use Each Doc

- **Starting out?** → `quick-start-guide.md`
- **Installing Libvirt?** → `libvirt-setup.md`
- **Choosing a path?** → `choosing-your-path.md`
- **Understanding progression?** → `learning-progression.md`
- **Need course details?** → `course-catalog.md`
- **Preparing base images?** → `base-image-preparation.md`
- **Having issues?** → `troubleshooting.md`
- **Need definitions?** → `glossary.md`

---

## 🎓 TF-100: Terraform Fundamentals (6 hours)

**Purpose**: Learn Terraform basics with Libvirt provider

```
TF-100-fundamentals/
├── README.md                  # TF-100 series overview
│
├── TF-101-intro-basics/       # Introduction (1.5h)
│   ├── README.md
│   └── example/
│       ├── main.tf
│       ├── providers.tf
│       └── README.md
│
├── TF-102-variables-loops/    # Variables & Loops (1.5h)
│   ├── README.md              # Course overview
│   ├── 1-variables/           # Variable types and usage
│   │   ├── README.md
│   │   └── example/
│   ├── 2-loops/               # for_each and count
│   │   ├── README.md
│   │   └── example/
│   ├── 3-env-vars/            # Environment variables
│   │   ├── README.md
│   │   └── example/
│   └── 4-functions/           # Built-in functions
│       ├── README.md
│       └── example/
│
├── TF-103-infrastructure/     # Infrastructure (2h)
│   ├── README.md              # Course overview
│   ├── 1-networks/            # Libvirt networks
│   │   ├── README.md
│   │   └── example/
│   ├── 2-security/            # Security groups
│   │   ├── README.md
│   │   └── example/
│   └── 3-virtual-machines/    # VM resources
│       ├── README.md
│       └── example/
│
└── TF-104-state-cli/          # State & CLI (1h)
    ├── README.md              # Course overview
    ├── 1-cli/                 # Terraform CLI commands
    │   ├── README.md
    │   └── example/
    ├── 2-state/               # State management
    │   ├── README.md
    │   └── example/
    ├── 3-modules-intro/       # Introduction to modules
    │   ├── README.md
    │   └── example/
    └── 4-debugging/           # Debugging techniques
        ├── README.md
        └── example/
```

### Directory Pattern

Each course follows this pattern:
```
TF-XXX-course-name/
├── README.md          # Course overview
├── 1-topic/           # First topic (if consolidated)
│   ├── README.md      # Topic explanation
│   └── example/       # Working code
│       ├── main.tf
│       ├── variables.tf (if needed)
│       ├── outputs.tf (if needed)
│       └── README.md
├── 2-topic/           # Second topic
└── ...
```

---

## 🚀 TF-200: Terraform Modules (6 hours)

**Purpose**: Advanced module design and patterns

```
TF-200-modules/
├── README.md                  # TF-200 series overview
│
├── TF-201-module-design/      # Module Design (1.5h)
│   ├── README.md              # Module structure and best practices
│   └── example/
│       ├── main.tf
│       └── modules/
│           └── network/
│               ├── main.tf
│               ├── variables.tf
│               └── outputs.tf
│
├── TF-202-advanced-patterns/  # Advanced Patterns (1.5h)
│   ├── README.md              # Course overview
│   ├── 1-private-registry/    # Private module registry
│   │   ├── README.md
│   │   └── example/
│   └── 2-canary-deployments/  # Canary deployment patterns
│       ├── README.md
│       └── example/
│
├── TF-203-yaml-config/        # YAML Configuration (1.5h)
│   ├── README.md              # YAML-driven infrastructure
│   └── example/
│       ├── main.tf
│       ├── config.yaml
│       └── README.md
│
└── TF-204-import-migration/   # Import & Migration (1.5h)
    ├── README.md              # Import blocks and state migration
    └── example/
        ├── main.tf
        ├── import.tf
        └── README.md
```

---

## 🧪 TF-300: Testing & Validation (5 hours)

**Purpose**: Testing, validation, and policy enforcement

```
TF-300-advanced/
├── README.md                  # TF-300 series overview
│
├── TF-301-validation/         # Validation (1.5h)
│   ├── README.md              # Course overview
│   ├── 1-variable-conditions/ # Variable validation blocks
│   │   ├── README.md
│   │   └── example/
│   └── 2-advanced-functions/  # Advanced built-in functions
│       ├── README.md
│       └── example/
│
├── TF-302-conditions-checks/  # Conditions & Checks (1.5h)
│   ├── README.md              # Course overview
│   ├── 1-pre-postconditions/  # Pre/post condition blocks
│   │   ├── README.md
│   │   └── example/
│   └── 2-check-blocks/        # Check blocks (Terraform 1.5+)
│       ├── README.md
│       └── example/
│
├── TF-303-test-framework/     # Test Framework (1h) [PLANNED]
│   ├── README.md
│   └── example/
│       ├── main.tf
│       ├── tests/
│       │   ├── basic.tftest.hcl
│       │   └── integration.tftest.hcl
│       └── README.md
│
└── TF-304-policy-code/        # Policy as Code (1h) [PLANNED]
    ├── README.md
    └── example/
        ├── policies/
        │   └── security.sentinel
        ├── test/
        └── README.md
```

---

## 🏢 TF-400: HCP Terraform & Enterprise (5 hours)

**Purpose**: Master HCP Terraform, remote runs, security, and Sentinel policies

```
TF-400-hcp-enterprise/
├── README.md                  # TF-400 series overview
│
├── TF-401-hcp-fundamentals/   # HCP Fundamentals (1h)
│   ├── README.md
│   └── examples/
│       ├── 01-cloud-block/
│       │   └── main.tf
│       └── 02-state-migration/
│           └── main.tf
│
├── TF-402-remote-runs/        # Remote Runs & GitOps (1.5h)
│   ├── README.md
│   └── examples/
│       ├── 01-vcs-workspace/
│       │   └── main.tf
│       └── 02-run-triggers/
│           └── main.tf
│
├── TF-403-security-access/    # Security & Access Control (1.5h)
│   ├── README.md
│   └── examples/
│       └── 01-team-management/
│           └── main.tf
│
└── TF-404-sentinel-policies/  # Sentinel Policies (1h)
    ├── README.md
    └── examples/
        ├── 01-restrict-memory/
        │   ├── restrict-vm-memory.sentinel
        │   └── test/
        └── 02-policy-set/
            └── main.tf
```

---

## 🖼️ PKR-100: Packer Fundamentals (4 hours)

**Purpose**: Build custom VM images

```
PKR-100-fundamentals/
├── README.md                  # PKR-100 series overview
│
├── PKR-101-intro/             # Introduction (1h)
│   ├── README.md              # Packer concepts and first template
│   └── example/
│       ├── ubuntu.pkr.hcl
│       └── README.md
│
├── PKR-102-qemu-provisioners/ # QEMU & Provisioners (1h)
│   ├── README.md              # QEMU builder and shell provisioners
│   └── example/
│       ├── linux.pkr.hcl
│       ├── scripts/
│       │   └── setup.sh
│       └── README.md
│
├── PKR-103-ansible/           # Ansible Integration (1.5h)
│   ├── README.md              # Ansible provisioner for Packer
│   └── example/
│       ├── ubuntu.pkr.hcl
│       ├── playbooks/
│       │   ├── basic.yml
│       │   ├── intermediate.yml
│       │   └── advanced.yml
│       └── README.md
│
└── PKR-104-versioning-hcp/    # Versioning & HCP (0.5h)
    ├── README.md              # Image versioning and HCP Packer
    └── example/
        ├── versioned.pkr.hcl
        └── README.md
```

---

## ☁️ Cloud Modules (Optional)

**Purpose**: Apply concepts to cloud providers

```
cloud-modules/
├── README.md                  # Cloud modules overview
│
├── AWS-200-terraform/         # AWS Module
│   ├── README.md
│   ├── AWS-201-setup/
│   │   └── authentication.md
│   ├── AWS-202-compute/
│   │   └── example/
│   ├── AWS-203-networking/
│   ├── AWS-204-security/
│   ├── AWS-205-storage/
│   ├── AWS-206-advanced/
│   └── AWS-207-labs/
│
├── AZ-200-terraform/          # Azure Module
│   ├── README.md
│   ├── AZ-201-setup/
│   ├── AZ-202-compute/
│   ├── AZ-203-networking/
│   ├── AZ-204-security/
│   ├── AZ-205-storage/
│   ├── AZ-206-advanced/
│   └── AZ-207-labs/
│
└── MC-300-multi-cloud/        # Multi-Cloud Patterns
    ├── README.md
    ├── MC-301-strategy/
    ├── MC-302-abstraction/
    ├── MC-303-networking/
    └── MC-304-labs/
```

---

## 🗂️ Example Directory Deep Dive

### Typical Example Structure

```
example/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── terraform.tfvars.example   # Example variable values
├── README.md                  # How to use this example
└── .gitignore                 # Ignore Terraform files
```

### What Each File Does

**main.tf**
- Primary Terraform configuration
- Defines providers and resources
- Contains the core logic

**variables.tf**
- Declares input variables
- Defines types and defaults
- Includes descriptions

**outputs.tf**
- Defines output values
- Shows important information after apply
- Used for module outputs

**terraform.tfvars.example**
- Example variable values
- Copy to `terraform.tfvars` and customize
- Not committed to git (contains sensitive data)

**README.md**
- Explains what the example does
- Lists prerequisites
- Provides step-by-step instructions
- Shows expected output

---

## 📝 File Naming Conventions

### Terraform Files
- `main.tf` - Main configuration
- `variables.tf` - Variable declarations
- `outputs.tf` - Output declarations
- `providers.tf` - Provider configuration (if separate)
- `versions.tf` - Version constraints (if separate)
- `locals.tf` - Local values (if many)
- `data.tf` - Data sources (if many)

### Packer Files
- `*.pkr.hcl` - Packer configuration
- `variables.pkr.hcl` - Variable declarations
- `sources.pkr.hcl` - Source definitions (if separate)

### Documentation
- `README.md` - Section/example documentation
- `*.md` - Additional documentation

### Scripts
- `*.sh` - Shell scripts
- `*.ps1` - PowerShell scripts
- `*.yml` or `*.yaml` - Ansible playbooks

---

## 🔍 Finding What You Need

### By Learning Goal

**Want to learn basics?**
→ `TF-100-fundamentals/TF-101-intro-basics/`

**Want to use variables?**
→ `TF-100-fundamentals/TF-102-variables-loops/`

**Want to create VMs?**
→ `TF-100-fundamentals/TF-103-infrastructure/3-virtual-machines/`

**Want to write modules?**
→ `TF-200-modules/TF-201-module-design/`

**Want to test code?**
→ `TF-300-advanced/TF-303-test-framework/`

**Want to build images?**
→ `PKR-100-fundamentals/`

**Want to use AWS?**
→ `cloud-modules/AWS-200-terraform/`

**Want to use Azure?**
→ `cloud-modules/AZ-200-terraform/`

### By Concept

**Variables**
- Introduction: `TF-100-fundamentals/TF-102-variables-loops/1-variables/`
- Advanced: `TF-300-advanced/TF-301-validation/1-variable-conditions/`

**Loops**
- Introduction: `TF-100-fundamentals/TF-102-variables-loops/2-loops/`
- Advanced: `TF-200-modules/TF-203-yaml-config/`

**Modules**
- Introduction: `TF-100-fundamentals/TF-104-state-cli/3-modules-intro/`
- Design: `TF-200-modules/TF-201-module-design/`
- Patterns: `TF-200-modules/TF-202-advanced-patterns/`

**Testing**
- Validation: `TF-300-advanced/TF-301-validation/`
- Conditions: `TF-300-advanced/TF-302-conditions-checks/`
- Framework: `TF-300-advanced/TF-303-test-framework/`

**State**
- Introduction: `TF-100-fundamentals/TF-104-state-cli/2-state/`
- Import: `TF-200-modules/TF-204-import-migration/`

**Networking**
- Libvirt: `TF-100-fundamentals/TF-103-infrastructure/1-networks/`
- AWS: `cloud-modules/AWS-200-terraform/AWS-203-networking/`
- Azure: `cloud-modules/AZ-200-terraform/AZ-203-networking/`

---

## 🎯 Navigation Tips

### 1. Always Start with README.md
Every directory has a README explaining:
- What you'll learn
- Prerequisites
- How to use examples
- Next steps

### 2. Follow the Course Numbers
Courses are numbered for a reason:
- TF-101 comes before TF-102
- Complete in order for best results
- Each builds on previous knowledge

### 3. Use Example Directories
- `example/` directories contain working code
- Copy and modify for your own use
- Read the example README first

### 4. Check Documentation First
Before diving into code:
- Read `docs/quick-start-guide.md`
- Understand the concept in course README
- Review example README

### 5. Understand Consolidated Courses
Some courses combine multiple topics:
- TF-102: 4 topics (variables, loops, env-vars, functions)
- TF-103: 3 topics (networks, security, VMs)
- TF-104: 4 topics (CLI, state, modules, debugging)
- Each topic has its own subdirectory

---

## 📊 Directory Statistics

### Core Training Structure
- **TF-100 Series**: 4 courses, 12 topics
- **TF-200 Series**: 4 courses, 6 topics
- **TF-300 Series**: 4 courses (2 active, 2 planned), 6 topics
- **PKR-100 Series**: 4 courses
- **Total**: 16 courses, ~30 hands-on sections

### Cloud Modules (Optional)
- **AWS-200**: 7 courses
- **AZ-200**: 7 courses
- **MC-300**: 4 courses

### Documentation
- **Guides**: 10+ documents
- **Examples**: 30+ working examples
- **Total Pages**: 150+ pages of documentation

---

## 🔄 Keeping Organized

### Your Workspace

Create a separate workspace for your work:

```bash
# Linux/macOS
mkdir ~/terraform-workspace
cd ~/terraform-workspace

# Copy examples here to modify
cp -r ~/hashi-training/TF-100-fundamentals/TF-101-intro-basics/example ./my-first-config

# Work on your copy
cd my-first-config
terraform init
terraform plan
```

```powershell
# Windows PowerShell
New-Item -ItemType Directory -Path "$HOME\terraform-workspace"
Set-Location "$HOME\terraform-workspace"

# Copy examples here to modify
Copy-Item -Recurse "$HOME\hashi-training\TF-100-fundamentals\TF-101-intro-basics\example" ".\my-first-config"

# Work on your copy
Set-Location ".\my-first-config"
terraform init
terraform plan
```

### Git Workflow

```bash
# Keep training repo clean
cd ~/hashi-training
git pull  # Get updates

# Work in your own repo
cd ~/terraform-workspace
git init
git add .
git commit -m "My learning progress"
```

---

## 🎓 Learning Path Through Directories

### Week 1: Fundamentals (TF-100)
```
Day 1: TF-101-intro-basics/
Day 2: TF-102-variables-loops/
Day 3-4: TF-103-infrastructure/
Day 5: TF-104-state-cli/
```

### Week 2: Modules (TF-200)
```
Day 1: TF-201-module-design/
Day 2: TF-202-advanced-patterns/
Day 3: TF-203-yaml-config/
Day 4-5: TF-204-import-migration/
```

### Week 3: Advanced (TF-300)
```
Day 1: TF-301-validation/
Day 2: TF-302-conditions-checks/
Day 3: TF-303-test-framework/
Day 4-5: TF-304-policy-code/
```

### Week 4: Packer & Cloud (Optional)
```
Day 1-2: PKR-100-fundamentals/
Day 3-5: cloud-modules/AWS-200-terraform/ or AZ-200-terraform/
```

---

## 📚 Additional Resources

### In This Repository
- Main README: `README.md`
- Quick Start: `docs/quick-start-guide.md`
- Course Catalog: `docs/course-catalog.md`
- All Docs: `docs/` directory

### External
- Terraform Docs: https://developer.hashicorp.com/terraform
- Packer Docs: https://developer.hashicorp.com/packer
- Libvirt Docs: https://libvirt.org/

---

## 🤔 Questions?

- Check course README files
- Review `docs/faq.md`
- See `docs/troubleshooting.md`
- Check `docs/course-catalog.md` for course details
- Create a GitHub issue

---

**Ready to navigate?** Start with [Quick Start Guide](quick-start-guide.md)!