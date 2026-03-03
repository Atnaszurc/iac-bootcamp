# Hashi-Training Quick Start Guide

**Welcome!** This guide will help you get started with the Zero-to-Hero Terraform and Packer training.

---

## 🎯 Training Overview

This training takes you from zero knowledge to advanced Terraform and Packer skills through a modular, hands-on approach using a professional university-style course structure.

### Training Structure

```
Core Training (FREE - Required) - 21 hours
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
├── TF-300: Testing, Validation & Policy (5 hours)
│   ├── TF-301: Input Validation & Advanced Functions (1.5h)
│   ├── TF-302: Pre/Post Conditions & Check Blocks (1.5h)
│   ├── TF-303: Terraform Test Framework (1h) [planned]
│   └── TF-304: Policy as Code (1h) [planned]
│
└── PKR-100: Packer Fundamentals (4 hours)
    ├── PKR-101: Introduction to Image Building (1h)
    ├── PKR-102: QEMU Builder & Provisioners (1h)
    ├── PKR-103: Ansible Configuration Management (1.5h)
    └── PKR-104: Image Versioning & HCP Packer (0.5h)

Cloud Provider Modules (OPTIONAL - Choose Your Path)
├── AWS-200: Apply concepts to AWS
├── AZ-200: Apply concepts to Azure
└── MC-300: Advanced multi-cloud patterns
```

### Why This Approach?

- **Zero Cost**: Complete core training without cloud expenses
- **Real Infrastructure**: Learn with actual VMs using Libvirt
- **Professional Structure**: University-style course numbering (100-400 levels)
- **Flexible**: Choose your cloud path after mastering fundamentals
- **Practical**: Hands-on labs and real-world examples

---

## 📋 Prerequisites

### Required Knowledge
- Basic command-line skills (bash/terminal)
- Text editor familiarity (VS Code, vim, nano, etc.)
- Basic understanding of:
  - What a virtual machine is
  - Basic networking concepts (IP addresses, networks)
  - Version control (git) - helpful but not required

### System Requirements
- **CPU**: 64-bit with virtualization support (Intel VT-x or AMD-V)
- **RAM**: 8 GB minimum (16 GB recommended)
- **Disk**: 50 GB free space (100 GB recommended)
- **OS**: Linux, macOS, or Windows 10/11 with WSL2

### Software to Install
1. **Libvirt** - Local virtualization platform
2. **Terraform** - Infrastructure as Code tool
3. **Packer** - Image building tool (for Packer section)
4. **Git** - Version control (optional but recommended)

---

## 🚀 Getting Started

### Step 1: Install Libvirt

Follow the comprehensive installation guide for your platform:

📖 **[Libvirt Setup Guide](libvirt-setup.md)**

This guide covers:
- Installation for Linux, macOS, and Windows (WSL2)
- Network configuration
- Verification script
- Troubleshooting

**Time Required**: 30-60 minutes

---

### Step 2: Install Terraform

#### Linux (Ubuntu/Debian)
```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Terraform
sudo apt update && sudo apt install terraform

# Verify installation
terraform version
```

#### macOS
```bash
# Using Homebrew
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verify installation
terraform version
```

#### Windows (WSL2)
```bash
# Same as Linux instructions above
# Run in your WSL2 Ubuntu terminal
```

**Official Documentation**: https://developer.hashicorp.com/terraform/install

---

### Step 3: Install Terraform Libvirt Provider

The Libvirt provider will be automatically downloaded when you run `terraform init` in your first project.

Verify provider availability:
```bash
# Create a test directory
mkdir -p ~/terraform-test && cd ~/terraform-test

# Create a simple provider configuration
cat > main.tf << 'EOF'
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
EOF

# Initialize Terraform (downloads provider)
terraform init

# Verify
terraform providers
```

---

### Step 4: Clone Training Repository

```bash
# Clone the repository
git clone <repository-url> hashi-training
cd hashi-training

# Verify structure
ls -la
```

Expected structure:
```
hashi-training/
├── docs/                      # Documentation
├── TF-100-fundamentals/       # 100-level courses (6h)
├── TF-200-modules/            # 200-level courses (6h)
├── TF-300-advanced/           # 300-level courses (5h)
├── TF-400-hcp-enterprise/     # 400-level expert courses (5h)
├── PKR-100-fundamentals/      # Packer training (4h)
└── cloud-modules/             # Optional cloud modules
```

---

## 📚 Learning Path

### Core Training Path (Required)

#### 1. TF-100: Terraform Fundamentals (6 hours)
**Location**: `TF-100-fundamentals/`

**What You'll Learn**:
- Infrastructure as Code concepts
- Terraform basics (providers, resources, variables)
- State management
- Terraform CLI commands
- Working with Libvirt provider

**Courses**:
- **TF-101**: Introduction to IaC & Terraform Basics
- **TF-102**: Variables, Loops & Functions
- **TF-103**: Infrastructure Resources (networks, VMs, storage)
- **TF-104**: State Management & CLI

**Start Here**: `TF-100-fundamentals/TF-101-intro-basics/README.md`

---

#### 2. TF-200: Terraform Modules & Patterns (6 hours)
**Location**: `TF-200-modules/`

**What You'll Learn**:
- Advanced module design
- Module composition
- YAML-driven configuration
- Import blocks for existing infrastructure
- Deployment patterns

**Prerequisites**: Complete TF-100

**Courses**:
- **TF-201**: Module Design & Composition
- **TF-202**: Advanced Module Patterns (Registry, Canary)
- **TF-203**: YAML-Driven Configuration
- **TF-204**: Import & Migration Strategies

**Start Here**: `TF-200-modules/TF-201-module-design/README.md`

---

#### 3. TF-300: Testing, Validation & Policy (5 hours)
**Location**: `TF-300-advanced/`

**What You'll Learn**:
- Input validation techniques
- Pre/post conditions
- Check blocks
- Advanced functions
- Testing strategies (planned)
- Policy as code (planned)

**Prerequisites**: Complete TF-200

**Courses**:
- **TF-301**: Input Validation & Advanced Functions
- **TF-302**: Pre/Post Conditions & Check Blocks
- **TF-303**: Terraform Test Framework (planned)
- **TF-304**: Policy as Code (planned)

**Start Here**: `TF-300-advanced/TF-301-validation/README.md`

---

#### 4. PKR-100: Packer Fundamentals (4 hours)
**Location**: `PKR-100-fundamentals/`

**What You'll Learn**:
- What Packer is and why use it
- QEMU builder for Libvirt
- Provisioners (shell, Ansible)
- Image versioning and tagging

**Prerequisites**: Complete TF-101 (minimum)

**Courses**:
- **PKR-101**: Introduction to Image Building
- **PKR-102**: QEMU Builder & Provisioners
- **PKR-103**: Ansible Configuration Management
- **PKR-104**: Image Versioning & HCP Packer

**Start Here**: `PKR-100-fundamentals/PKR-101-intro/README.md`

---

### Cloud Provider Modules (Optional)

After completing core training, choose your cloud path:

#### AWS-200 Module
**Location**: `cloud-modules/AWS-200-terraform/`

**What You'll Learn**:
- Apply Terraform concepts to AWS
- EC2, VPC, S3, RDS
- AWS-specific patterns
- Migration from Libvirt to AWS

**Prerequisites**: Complete core training + AWS account

---

#### AZ-200 Module
**Location**: `cloud-modules/AZ-200-terraform/`

**What You'll Learn**:
- Apply Terraform concepts to Azure
- VMs, VNets, Storage Accounts
- Azure-specific patterns
- Migration from Libvirt to Azure

**Prerequisites**: Complete core training + Azure subscription

---

#### MC-300 Multi-Cloud Module
**Location**: `cloud-modules/MC-300-multi-cloud/`

**What You'll Learn**:
- Multi-cloud strategies
- Provider abstraction
- Cross-cloud networking
- Disaster recovery patterns

**Prerequisites**: Complete at least one cloud module

---

## 🎓 Study Tips

### 1. Hands-On Practice
- **Don't just read** - type out every example
- **Experiment** - modify examples to see what happens
- **Break things** - learn from errors

### 2. Use the Documentation
- Terraform docs: https://developer.hashicorp.com/terraform
- Libvirt provider: https://registry.terraform.io/providers/dmacvicar/libvirt
- Keep documentation open while working

### 3. Take Notes
- Document what you learn
- Keep a "gotchas" list
- Save useful commands

### 4. Pace Yourself
- Each course has estimated time
- Take breaks between courses
- Don't rush - understanding > speed

### 5. Join the Community
- Ask questions when stuck
- Share your progress
- Help others when you can

---

## 🔧 Troubleshooting

### Common Issues

#### "Cannot connect to libvirt"
```bash
# Check if libvirt is running
sudo systemctl status libvirtd

# Start if needed
sudo systemctl start libvirtd

# Check user permissions
groups | grep libvirt
```

#### "Provider not found"
```bash
# Re-initialize Terraform
terraform init

# Clear cache if needed
rm -rf .terraform .terraform.lock.hcl
terraform init
```

#### "Permission denied /dev/kvm"
```bash
# Add user to kvm group
sudo usermod -aG kvm $USER

# Log out and log back in
```

### Getting Help

1. **Check the docs**: Most issues are covered in documentation
2. **Search existing issues**: Someone may have had the same problem
3. **Ask in discussions**: Use the repository discussions
4. **Create an issue**: If you found a bug or have a suggestion

---

## 📊 Progress Tracking

### Recommended Approach

1. **Create a learning journal**:
   ```bash
   mkdir ~/terraform-learning
   cd ~/terraform-learning
   echo "# My Terraform Learning Journey" > journal.md
   ```

2. **Track completed courses**:
   - [ ] TF-101: Introduction to IaC & Terraform Basics
   - [ ] TF-102: Variables, Loops & Functions
   - [ ] TF-103: Infrastructure Resources
   - [ ] TF-104: State Management & CLI
   - [ ] TF-201: Module Design & Composition
   - [ ] TF-202: Advanced Module Patterns
   - [ ] TF-203: YAML-Driven Configuration
   - [ ] TF-204: Import & Migration Strategies
   - [ ] TF-301: Input Validation & Advanced Functions
   - [ ] TF-302: Pre/Post Conditions & Check Blocks
   - [ ] PKR-101: Introduction to Image Building
   - [ ] PKR-102: QEMU Builder & Provisioners
   - [ ] PKR-103: Ansible Configuration Management
   - [ ] PKR-104: Image Versioning & HCP Packer
   - [ ] Cloud Module (specify which)

3. **Save your work**:
   ```bash
   # Create a personal workspace
   mkdir ~/terraform-workspace
   # Save your examples and experiments here
   ```

---

## 🎯 Success Criteria

You'll know you've mastered the core training when you can:

- ✅ Explain what Infrastructure as Code is and why it's valuable
- ✅ Write Terraform configurations from scratch
- ✅ Create and use Terraform modules
- ✅ Manage Terraform state effectively
- ✅ Implement validation and testing strategies
- ✅ Build custom images with Packer
- ✅ Debug Terraform issues independently
- ✅ Apply concepts to any cloud provider

---

## 🚀 Next Steps After Core Training

### Option 1: Cloud Certification
- AWS Certified Solutions Architect
- Azure Administrator
- Google Cloud Associate

### Option 2: Advanced Topics
- Terraform Cloud/Enterprise
- GitOps with Terraform
- Policy as Code at scale
- Multi-cloud architectures

### Option 3: Real Projects
- Migrate existing infrastructure to Terraform
- Build a personal cloud lab
- Contribute to open-source Terraform modules

---

## 📖 Additional Resources

### Official Documentation
- **Terraform**: https://developer.hashicorp.com/terraform
- **Packer**: https://developer.hashicorp.com/packer
- **Libvirt**: https://libvirt.org/

### Community Resources
- **Terraform Registry**: https://registry.terraform.io/
- **HashiCorp Learn**: https://learn.hashicorp.com/
- **Terraform Best Practices**: https://www.terraform-best-practices.com/

### Books (Optional)
- "Terraform: Up & Running" by Yevgeniy Brikman
- "Infrastructure as Code" by Kief Morris

---

## 🎉 Ready to Start?

1. ✅ Libvirt installed and verified
2. ✅ Terraform installed
3. ✅ Repository cloned
4. ✅ Reviewed course structure

**Begin your journey**: 

```bash
cd hashi-training/TF-100-fundamentals/TF-101-intro-basics
cat README.md
```

---

**Questions?** Check the [Course Catalog](course-catalog.md) or [FAQ](faq.md)

**Good luck on your Infrastructure as Code journey!** 🚀