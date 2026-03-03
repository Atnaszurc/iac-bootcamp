# Hashi-Training: Zero-to-Hero Terraform & Packer

**A comprehensive, hands-on training program to master Infrastructure as Code**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-1.14+-purple.svg)](https://www.terraform.io/)
[![Packer](https://img.shields.io/badge/Packer-1.14+-blue.svg)](https://www.packer.io/)

---

## 🎯 What is This?

This training program takes you from **zero knowledge** to **advanced proficiency** in Terraform and Packer through a structured, university-style course progression. Learn Infrastructure as Code concepts using free, local virtualization before optionally applying them to cloud providers.

### Key Features

- ✅ **Zero Cost Core Training** - Learn with Libvirt (local VMs)
- ✅ **University-Style Structure** - Clear progression (100-400 levels)
- ✅ **Hands-On Labs** - Practice with real infrastructure
- ✅ **Modular Design** - Choose your learning path
- ✅ **Production-Ready Skills** - Enterprise-grade patterns
- ✅ **Cloud-Agnostic** - Concepts apply to any provider
- ✅ **Modern Terraform** - Latest features (1.14+)

---

## 📚 Training Structure

### Core Training (FREE - Required)

**Duration**: 21 hours (realistic estimate)  
**Cost**: $0  
**Platform**: Libvirt (local VMs)

```
TF-100: Terraform Fundamentals (6 hours)
├── TF-101: Introduction to IaC & Terraform Basics (1.5h)
│   └── [+] terraform_data vs null_resource, local-exec provisioner
├── TF-102: Variables, Loops & Functions (1.5h)
│   └── [+] for expressions (list/map comprehensions)
├── TF-103: Infrastructure Resources (2h)
└── TF-104: State Management & CLI (1h)
    └── [+] terraform console as a learning tool

TF-200: Terraform Modules & Patterns (6 hours)
├── TF-201: Module Design & Composition (1.5h)
│   └── [+] moved blocks (Terraform 1.1+)
├── TF-202: Advanced Module Patterns (1.5h)
├── TF-203: YAML-Driven Configuration (1.5h)
│   └── [+] jsondecode() and JSON-driven configuration
└── TF-204: Import & Migration Strategies (1.5h)
    └── [+] removed blocks (Terraform 1.7+)

TF-300: Testing, Validation & Advanced Features (8 hours)
├── TF-301: Input Validation & Advanced Functions (1.5h)
│   └── [+] sensitive variables, outputs & nonsensitive()
│   └── [+] ephemeral variables & outputs (1.10+)
│   └── [+] cross-variable validation (1.9+)
├── TF-302: Pre/Post Conditions & Check Blocks (1.5h)
│   └── [+] lifecycle meta-arguments (complete unit)
│   └── [+] write-only attributes (1.11+)
├── TF-303: Terraform Test Framework (1h)
│   └── [+] JUnit XML output, parallel runs, override_during (1.11-1.12)
├── TF-304: Policy as Code - OPA/Rego (1h)
├── TF-305: Workspaces & Remote State (1.5h)
│   └── [+] S3 native state locking (1.11+)
├── TF-306: Terraform Functions Deep Dive (1.5h)
│   └── [+] templatestring, ephemeralasnull, element() negative indices (1.9-1.10)
└── TF-307: List Resources, terraform query & Actions (1h) [NEW — 1.14]

TF-400: HCP Terraform & Enterprise Features (6 hours)
├── TF-401: HCP Terraform Fundamentals (1.5h)
├── TF-402: Remote Runs & VCS Integration (1.5h)
├── TF-403: Security & Access Control (1h)
├── TF-404: Sentinel Policy as Code (1h)
└── TF-405: Terraform Stacks (1h) [NEW — 1.13]

PKR-100: Packer Fundamentals (4 hours)
├── PKR-101: Introduction to Image Building (1h)
├── PKR-102: QEMU Builder & Provisioners (1h)
│   └── [+] post-processors (shell-local, manifest)
├── PKR-103: Ansible Configuration Management (1.5h)
│   └── [+] Packer variables & .pkrvars.hcl files
└── PKR-104: Image Versioning & HCP Packer (0.5h)
```

### Cloud Provider Modules (OPTIONAL)

**Choose your path after completing core training:**

- **AWS-200**: Apply concepts to AWS (EC2, VPC, S3, RDS)
- **AZ-200**: Apply concepts to Azure (VMs, VNets, Storage)
- **MC-300**: Advanced multi-cloud patterns

---

## 🚀 Quick Start

### Prerequisites

- **System**: Linux, macOS, or Windows 10/11 with WSL2
- **RAM**: 8 GB minimum (16 GB recommended)
- **Disk**: 50 GB free space
- **CPU**: Virtualization support (Intel VT-x or AMD-V)

### Installation (5 Steps)

1. **Install Libvirt**
   ```bash
   # Ubuntu/Debian
   sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients
   
   # macOS
   brew install qemu libvirt
   
   # See docs/libvirt-setup.md for detailed instructions
   ```

2. **Install Terraform**
   ```bash
   # Ubuntu/Debian
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install terraform
   
   # macOS
   brew tap hashicorp/tap
   brew install hashicorp/tap/terraform
   ```

3. **Verify Installation**
   ```bash
   terraform version
   virsh version
   ```

4. **Clone Repository**
   ```bash
   git clone <repository-url> hashi-training
   cd hashi-training
   ```

5. **Start Learning**
   ```bash
   # Read the quick start guide
   cat docs/quick-start-guide.md
   
   # Begin with TF-101
   cd TF-100-fundamentals/TF-101-intro-basics
   cat README.md
   ```

---

## 📖 Documentation

### Getting Started
- **[Quick Start Guide](docs/quick-start-guide.md)** - Get up and running quickly
- **[Libvirt Setup](docs/libvirt-setup.md)** - Detailed installation guide
- **[Course Catalog](docs/course-catalog.md)** - Complete course descriptions

### Planning Your Journey
- **[Choosing Your Path](docs/choosing-your-path.md)** - Decide which modules to take
- **[Learning Progression](docs/learning-progression.md)** - Understand how concepts build
- **[Directory Structure](docs/directory-structure.md)** - Navigate the repository

### Reference
- **[FAQ](docs/faq.md)** - Frequently asked questions
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

---

## 🎓 Learning Paths

### Path 1: Core Training Only (FREE)
**Best for**: Beginners, budget-conscious learners, local development

```
Week 1-2: TF-100 (Fundamentals)
Week 3-4: TF-200 (Modules & Patterns)
Week 5-6: TF-300 (Testing & Policy)
Week 7: PKR-100 (Packer)
└── Master IaC fundamentals with zero cost
```

**Outcome**: Strong foundation, ready for any cloud provider

---

### Path 2: Core + AWS
**Best for**: AWS-focused careers, most popular cloud

```
Week 1-6: Core Training (TF-100, TF-200, TF-300)
Week 7-8: AWS-200 Module
└── Production-ready AWS Terraform skills
```

**Outcome**: AWS Solutions Architect ready

---

### Path 3: Core + Azure
**Best for**: Enterprise environments, Microsoft shops

```
Week 1-6: Core Training (TF-100, TF-200, TF-300)
Week 7-8: AZ-200 Module
└── Production-ready Azure Terraform skills
```

**Outcome**: Azure Administrator ready

---

### Path 4: Core + Multi-Cloud
**Best for**: Advanced learners, multi-cloud environments

```
Week 1-6: Core Training
Week 7-8: AWS-200 Module
Week 9-10: AZ-200 Module
Week 11+: MC-300 Multi-Cloud Patterns
└── Multi-cloud expertise
```

**Outcome**: Cloud Architect ready

---

## 📂 Repository Structure

```
hashi-training/
├── docs/                              # Documentation
│   ├── libvirt-setup.md              # Installation guide
│   ├── quick-start-guide.md          # Getting started
│   ├── course-catalog.md             # Complete course list
│   ├── choosing-your-path.md         # Path selection guide
│   ├── learning-progression.md       # Concept progression
│   ├── directory-structure.md        # Repository layout
│   └── base-image-preparation.md    # Base image guide
│
├── TF-100-fundamentals/               # 100-level: Fundamentals
│   ├── README.md                     # Course overview
│   ├── TF-101-intro-basics/          # Introduction & basics
│   ├── TF-102-variables-loops/       # Variables, loops, functions
│   ├── TF-103-infrastructure/        # Networks, security, VMs
│   └── TF-104-state-cli/             # State, CLI, debugging
│
├── TF-200-modules/                    # 200-level: Intermediate
│   ├── README.md                     # Course overview
│   ├── TF-201-module-design/         # Module basics
│   ├── TF-202-advanced-patterns/     # Advanced patterns
│   ├── TF-203-yaml-config/           # YAML-driven config
│   └── TF-204-import-migration/      # Import strategies
│
├── TF-300-advanced/                   # 300-level: Advanced
│   ├── README.md                     # Course overview
│   ├── TF-301-validation/            # Input validation
│   ├── TF-302-conditions-checks/     # Conditions & checks
│   ├── TF-303-test-framework/        # Terraform test framework
│   ├── TF-304-policy-code/           # Policy as code (OPA/Rego)
│   ├── TF-305-workspaces-remote/     # Workspaces & remote state
│   └── TF-306-functions/             # Terraform functions deep dive
│
├── TF-400-hcp-enterprise/             # 400-level: Expert
│   ├── README.md                     # Course overview
│   ├── TF-401-hcp-fundamentals/      # HCP Terraform basics
│   ├── TF-402-remote-runs/           # Remote runs & VCS integration
│   ├── TF-403-security-access/       # Teams, RBAC, OIDC
│   └── TF-404-sentinel-policies/     # Sentinel policy as code
│
├── PKR-100-fundamentals/              # Packer training
│   ├── README.md                     # Course overview
│   ├── PKR-101-intro/                # Introduction
│   ├── PKR-102-qemu-provisioners/    # QEMU & provisioners
│   ├── PKR-103-ansible/              # Ansible integration
│   └── PKR-104-versioning-hcp/       # Versioning & HCP
│
└── cloud-modules/                     # Optional cloud modules
    ├── README.md                     # Cloud modules overview
    ├── AWS-200-terraform/            # AWS module
    ├── AZ-200-terraform/             # Azure module
    └── MC-300-multi-cloud/           # Multi-cloud patterns
```

---

## 🎯 What You'll Learn

### After Core Training

**Terraform Skills**:
- ✅ Write infrastructure as code
- ✅ Manage state effectively
- ✅ Create reusable modules
- ✅ Implement testing strategies
- ✅ Enforce policies
- ✅ Debug issues independently
- ✅ Use advanced validation techniques
- ✅ Import existing infrastructure

**Packer Skills**:
- ✅ Build custom VM images
- ✅ Automate image creation
- ✅ Use Ansible for configuration
- ✅ Version and manage images
- ✅ Integrate with HCP Packer

**Concepts Mastered**:
- ✅ Infrastructure as Code principles
- ✅ Declarative vs imperative
- ✅ Immutable infrastructure
- ✅ GitOps workflows
- ✅ Testing and validation
- ✅ Policy enforcement
- ✅ Module composition patterns

---

## 💡 Why This Training?

### Unique Approach

**1. University-Style Structure**
- Clear progression (100-400 levels)
- Professional course numbering
- Easy to reference and share
- Industry-standard organization

**2. Zero Cost Foundation**
- Learn without cloud expenses
- Practice with real VMs locally
- No credit card required

**3. Modular Design**
- Choose your own path
- Skip what you don't need
- Add modules as you grow

**4. Modern Features**
- Terraform 1.14+ features
- Ephemeral resources & values (1.10+)
- Write-only attributes (1.11+)
- Test framework with JUnit & parallel runs (1.11-1.12)
- S3 native state locking (1.11+)
- Identity-based import (1.12+)
- Terraform Stacks (1.13+)
- List resources & Actions block (1.14+)
- Latest best practices

**5. Production-Ready**
- Enterprise patterns
- Testing strategies
- Policy enforcement
- Real-world scenarios

**6. Cloud-Agnostic**
- Concepts apply everywhere
- Not locked to one provider
- Flexible career path

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Ways to Contribute
- 🐛 Report bugs
- 💡 Suggest improvements
- 📝 Improve documentation
- ✨ Add examples
- 🧪 Add tests
- 🎓 Create new courses

---

## 📜 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- HashiCorp for Terraform and Packer
- Libvirt community
- All contributors and learners

---

## 📞 Support

- **Documentation**: Check [docs/](docs/) directory
- **Issues**: Create a GitHub issue
- **Discussions**: Use GitHub Discussions
- **Community**: Join our community channels

---

## 🗺️ Roadmap

### Current Version: 3.3 (Terraform 1.9–1.14 Features Added)
- ✅ University-style course numbering (100-400 levels)
- ✅ Modular cloud approach
- ✅ Libvirt-based core training
- ✅ Terraform 1.14+ features
- ✅ Test framework integration
- ✅ Ansible provisioner examples
- ✅ Comprehensive documentation
- ✅ TF-305: Workspaces & Remote State (new course)
- ✅ TF-306: Terraform Functions Deep Dive (new course)
- ✅ Supplemental topics: terraform_data, for expressions, moved/removed blocks, sensitive values, lifecycle meta-arguments
- ✅ Packer additions: post-processors, variables & var-files
- ✅ TF-400: HCP Terraform & Enterprise Features (new expert course)
- ✅ Ephemeral resources & values (TF-301, Terraform 1.10+)
- ✅ Write-only attributes (TF-302, Terraform 1.11+)
- ✅ Test framework enhancements: JUnit XML, parallel runs, override_during (TF-303, 1.11-1.12)
- ✅ S3 native state locking — DynamoDB deprecated (TF-305, 1.11+)
- ✅ New functions: templatestring, ephemeralasnull, element() negative indices (TF-306, 1.9-1.10)
- ✅ Cross-variable validation (TF-301, 1.9+)
- ✅ Identity-based import (TF-204, 1.12+)
- ✅ TF-307: List Resources, terraform query & Actions (new course, 1.14+)
- ✅ TF-405: Terraform Stacks (new expert course, 1.13+)
- ✅ AWS provider v6 compatibility review & updates (cloud-modules)
- ✅ CLI documentation updates: new commands 1.9–1.14 (TF-104)

### Planned
- [ ] GCP cloud module
- [ ] Kubernetes integration examples
- [ ] Video tutorials
- [ ] Interactive labs

---

## 📊 Stats

- **Training Hours**: 32 (core) + optional cloud modules
- **Courses**: 28 (24 core + 4 cloud optional)
- **Hands-On Labs**: 70+
- **Code Examples**: 160+
- **Documentation Pages**: 35+

---

## 🚀 Get Started Now!

1. **Read**: [Quick Start Guide](docs/quick-start-guide.md)
2. **Install**: [Libvirt Setup](docs/libvirt-setup.md)
3. **Browse**: [Course Catalog](docs/course-catalog.md)
4. **Choose**: [Your Learning Path](docs/choosing-your-path.md)
5. **Learn**: Start with `TF-100-fundamentals/TF-101-intro-basics/README.md`

**Ready to master Infrastructure as Code?** Let's begin! 🎉

---

## 📚 Course Quick Reference

### TF-100 Series (Fundamentals)
- **TF-101**: Introduction to IaC & Terraform Basics
- **TF-102**: Variables, Loops & Functions
- **TF-103**: Infrastructure Resources (Networks, Security, VMs)
- **TF-104**: State Management & CLI

### TF-200 Series (Intermediate)
- **TF-201**: Module Design & Composition
- **TF-202**: Advanced Module Patterns (Registry, Canary)
- **TF-203**: YAML-Driven Configuration
- **TF-204**: Import & Migration Strategies

### TF-300 Series (Advanced)
- **TF-301**: Input Validation, Advanced Functions, Sensitive & Ephemeral Values
- **TF-302**: Pre/Post Conditions, Check Blocks, Lifecycle Meta-Arguments & Write-Only Attributes
- **TF-303**: Terraform Test Framework (JUnit XML, parallel runs, override_during)
- **TF-304**: Policy as Code - OPA/Rego
- **TF-305**: Workspaces & Remote State (S3 native locking)
- **TF-306**: Terraform Functions Deep Dive (templatestring, ephemeralasnull, element negative indices)
- **TF-307**: List Resources, terraform query & Actions *(NEW — 1.14)*

### TF-400 Series (Expert)
- **TF-401**: HCP Terraform Fundamentals
- **TF-402**: Remote Runs & VCS Integration
- **TF-403**: Security & Access Control
- **TF-404**: Sentinel Policy as Code (Enterprise)
- **TF-405**: Terraform Stacks *(NEW — 1.13)*

### PKR-100 Series (Packer)
- **PKR-101**: Introduction to Image Building
- **PKR-102**: QEMU Builder & Provisioners
- **PKR-103**: Ansible Configuration Management
- **PKR-104**: Image Versioning & HCP Packer

---

**Made with ❤️ for the IaC community**
