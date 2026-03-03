# TF-100: Terraform Fundamentals

**Level**: 100 (Beginner)  
**Duration**: 6 hours  
**Prerequisites**: None  
**Platform**: Libvirt (local VMs)

---

## 🎯 Course Overview

Welcome to **TF-100: Terraform Fundamentals**! This is your starting point for mastering Infrastructure as Code with Terraform. This course takes you from zero knowledge to confidently creating, managing, and understanding infrastructure using Terraform's declarative approach.

By the end of this course, you'll be able to write Terraform configurations, manage infrastructure state, and understand the core concepts that apply to any cloud provider or infrastructure platform.

---

## 📚 What You'll Learn

### Core Competencies

After completing TF-100, you will be able to:

- ✅ **Understand IaC Principles**: Grasp why Infrastructure as Code matters and how it transforms operations
- ✅ **Write Terraform Configurations**: Create infrastructure using HCL (HashiCorp Configuration Language)
- ✅ **Use Variables & Loops**: Build flexible, reusable configurations that adapt to different environments
- ✅ **Manage Infrastructure Resources**: Create networks, security groups, and virtual machines
- ✅ **Handle State Management**: Understand and manipulate Terraform state safely
- ✅ **Master the CLI**: Use Terraform commands effectively for daily workflows
- ✅ **Debug Issues**: Troubleshoot common problems and understand error messages

---

## 🗂️ Course Modules

### TF-101: Introduction to IaC & Terraform Basics
**Duration**: 1.5 hours  
**Directory**: `TF-101-intro-basics/`

Your first steps into Infrastructure as Code. Learn what Terraform is, how it works, and create your first infrastructure resources.

**Topics**:
- What is Infrastructure as Code?
- Terraform architecture and workflow
- Providers and their role
- Basic resource creation
- HCL syntax fundamentals
- Introduction to Libvirt provider

**Hands-On**:
- Install Terraform and Libvirt
- Create local files with `local_file` provider
- Configure Libvirt provider
- Create your first virtual network
- Run `terraform init`, `plan`, and `apply`

---

### TF-102: Variables, Loops & Functions
**Duration**: 1.5 hours  
**Directory**: `TF-102-variables-loops/`

Make your configurations dynamic and reusable. Learn to use variables, loops, and functions to create flexible infrastructure code.

**Topics**:
- **1-variables/**: Variable types, defaults, validation, and sensitive data
- **2-loops/**: `count` parameter, `for_each` with maps/sets, dynamic blocks
- **3-env-vars/**: Environment variables, .tfvars files, CLI variable passing
- **4-functions/**: String, collection, encoding, and filesystem functions

**Hands-On**:
- Create parameterized network configurations
- Use loops to create multiple VMs
- Read configuration from environment variables
- Apply functions to transform data
- Build a reusable module with variables

---

### TF-103: Infrastructure Resources
**Duration**: 2 hours  
**Directory**: `TF-103-infrastructure/`

Build real infrastructure with Terraform. Create networks, security configurations, and virtual machines using the Libvirt provider.

**Topics**:
- **1-networks/**: Virtual networks, subnets, DHCP, DNS configuration
- **2-security/**: Security groups, firewall rules, network isolation
- **3-virtual-machines/**: VM creation, cloud-init, resource dependencies

**Hands-On**:
- Create isolated virtual networks
- Configure security groups and firewall rules
- Launch virtual machines with cloud-init
- Build multi-VM infrastructure
- Manage resource dependencies

---

### TF-104: State Management & CLI
**Duration**: 1 hour  
**Directory**: `TF-104-state-cli/`

Master Terraform state and command-line tools. Learn how Terraform tracks infrastructure and how to use CLI commands effectively.

**Topics**:
- **1-cli/**: All Terraform commands (init, plan, apply, destroy, fmt, validate)
- **2-state/**: State file structure, state locking, backends, remote state
- **3-modules-intro/**: Introduction to modularizing infrastructure
- **4-debugging/**: Troubleshooting techniques, log levels, common errors

**Hands-On**:
- Manipulate state safely
- Use all major CLI commands
- Configure local backend
- Debug infrastructure issues
- Practice CLI workflow

---

## 🎓 Learning Path

### Recommended Progression

```
Week 1: TF-101 + TF-102
├── Day 1-2: TF-101 (Introduction & Basics)
└── Day 3-4: TF-102 (Variables, Loops & Functions)

Week 2: TF-103 + TF-104
├── Day 1-3: TF-103 (Infrastructure Resources)
└── Day 4-5: TF-104 (State Management & CLI)
```

### Time Commitment

- **Self-Paced**: 6 hours of core content
- **With Practice**: 8-10 hours (recommended)
- **Full Mastery**: 12-15 hours (includes experimentation)

---

## 🚀 Getting Started

### Prerequisites

Before starting TF-100, ensure you have:

1. **System Requirements**:
   - Linux, macOS, or Windows 10/11 with WSL2
   - 8 GB RAM minimum (16 GB recommended)
   - 50 GB free disk space
   - CPU with virtualization support (Intel VT-x or AMD-V)

2. **Software Installed**:
   - Terraform 1.14+ ([installation guide](../docs/libvirt-setup.md))
   - Libvirt/QEMU ([installation guide](../docs/libvirt-setup.md))
   - Git (for cloning examples)
   - Text editor (VS Code recommended)

3. **Knowledge**:
   - Basic command-line usage
   - Basic understanding of virtual machines
   - No prior Terraform or IaC experience needed!

### Quick Start

```bash
# 1. Navigate to the course directory
cd hashi-training/TF-100-fundamentals

# 2. Start with TF-101
cd TF-101-intro-basics
cat README.md

# 3. Follow the exercises in order
# Each module has its own README with detailed instructions
```

---

## 📖 Course Materials

### What's Included

Each module contains:

- **README.md**: Detailed explanations and learning objectives
- **example/**: Working Terraform configurations you can run
- **Exercises**: Hands-on labs to practice concepts
- **Solutions**: Reference implementations (where applicable)

### Directory Structure

```
TF-100-fundamentals/
├── README.md                          # This file
├── TF-101-intro-basics/
│   ├── README.md                      # Module guide
│   └── example/                       # Working examples
├── TF-102-variables-loops/
│   ├── README.md                      # Module overview
│   ├── 1-variables/                   # Variables section
│   ├── 2-loops/                       # Loops section
│   ├── 3-env-vars/                    # Environment variables
│   └── 4-functions/                   # Functions section
├── TF-103-infrastructure/
│   ├── README.md                      # Module overview
│   ├── 1-networks/                    # Network resources
│   ├── 2-security/                    # Security configuration
│   └── 3-virtual-machines/            # VM creation
└── TF-104-state-cli/
    ├── README.md                      # Module overview
    ├── 1-cli/                         # CLI commands
    ├── 2-state/                       # State management
    ├── 3-modules-intro/               # Module introduction
    └── 4-debugging/                   # Debugging guide
```

---

## 🎯 Learning Objectives

### By Module

#### After TF-101, you will:
- Understand what Infrastructure as Code is and why it matters
- Know how Terraform works (declarative vs imperative)
- Be able to configure and use providers
- Create basic infrastructure resources
- Execute the Terraform workflow (init → plan → apply)

#### After TF-102, you will:
- Declare and use variables effectively
- Implement loops for resource creation (count, for_each)
- Read configuration from environment variables
- Apply Terraform functions to manipulate data
- Create DRY (Don't Repeat Yourself) configurations

#### After TF-103, you will:
- Create and manage virtual networks
- Configure network security and firewall rules
- Launch and manage virtual machines
- Understand resource dependencies
- Use cloud-init for VM configuration

#### After TF-104, you will:
- Understand Terraform state and its importance
- Use all major Terraform CLI commands
- Manipulate state safely
- Debug common Terraform issues
- Understand module basics

---

## 🏆 Success Criteria

You've successfully completed TF-100 when you can:

- [ ] Write a Terraform configuration from scratch
- [ ] Use variables to make configurations flexible
- [ ] Create multiple resources using loops
- [ ] Build a complete infrastructure (network + VMs)
- [ ] Manage Terraform state confidently
- [ ] Debug issues using logs and error messages
- [ ] Explain IaC concepts to others
- [ ] Feel comfortable reading Terraform documentation

---

## 🔄 What's Next?

### After TF-100

Once you complete TF-100, you're ready for:

1. **TF-200: Terraform Modules & Patterns** (Intermediate)
   - Learn to create reusable modules
   - Master advanced patterns
   - Implement YAML-driven configuration
   - Import existing infrastructure

2. **PKR-100: Packer Fundamentals** (Can be taken in parallel)
   - Build custom VM images
   - Automate image creation
   - Use Ansible for configuration

3. **Practice Projects**:
   - Build a multi-tier application infrastructure
   - Create a development environment
   - Automate your homelab setup

---

## 💡 Tips for Success

### Best Practices

1. **Hands-On Practice**: Don't just read—type out the examples yourself
2. **Experiment**: Modify examples to see what happens
3. **Break Things**: Learn by making mistakes in a safe environment
4. **Take Notes**: Document what you learn in your own words
5. **Ask Questions**: Use GitHub Discussions if you get stuck

### Common Pitfalls to Avoid

- ❌ Skipping the basics to jump to advanced topics
- ❌ Not running the examples yourself
- ❌ Ignoring error messages instead of understanding them
- ❌ Copying code without understanding what it does
- ❌ Not practicing state management concepts

### Study Tips

- **Daily Practice**: 30-60 minutes per day is better than marathon sessions
- **Build Projects**: Apply concepts to real problems you want to solve
- **Review Regularly**: Revisit earlier modules to reinforce learning
- **Join Community**: Engage with other learners and experts

---

## 📚 Additional Resources

### Official Documentation

- [Terraform Documentation](https://www.terraform.io/docs)
- [Terraform Registry](https://registry.terraform.io/)
- [Libvirt Provider Docs](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs)
- [HCL Language Reference](https://www.terraform.io/language)

### Recommended Reading

- [Terraform: Up & Running](https://www.terraformupandrunning.com/) by Yevgeniy Brikman
- [Infrastructure as Code](https://www.oreilly.com/library/view/infrastructure-as-code/9781098114664/) by Kief Morris
- HashiCorp Learn Tutorials

### Community

- [Terraform GitHub Discussions](https://github.com/hashicorp/terraform/discussions)
- [r/Terraform](https://www.reddit.com/r/Terraform/)
- [HashiCorp Community Forum](https://discuss.hashicorp.com/c/terraform-core)

---

## 🐛 Troubleshooting

### Common Issues

**Libvirt Connection Issues**:
```bash
# Check if libvirt is running
sudo systemctl status libvirtd

# Verify user permissions
sudo usermod -aG libvirt $USER
```

**Terraform Provider Issues**:
```bash
# Clear provider cache
rm -rf .terraform/
terraform init
```

**State Lock Issues**:
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

For detailed troubleshooting, see:
- [Libvirt Setup Guide](../docs/libvirt-setup.md)
- [Troubleshooting Guide](../docs/troubleshooting.md)
- Module-specific README files

---

## 📊 Course Statistics

- **Total Modules**: 4
- **Total Sections**: 12
- **Hands-On Labs**: 15+
- **Code Examples**: 40+
- **Estimated Completion**: 6-15 hours (depending on pace)

---

## 🎓 Certification Path

While this course doesn't provide official certification, it prepares you for:

- **HashiCorp Certified: Terraform Associate**
- Real-world Terraform usage
- Advanced Terraform courses (TF-200, TF-300)
- Cloud provider certifications (AWS, Azure, GCP)

---

## 🤝 Contributing

Found an issue or want to improve the course?

- Report bugs via GitHub Issues
- Suggest improvements via Pull Requests
- Share your learning experience
- Help other learners in Discussions

---

## 📜 License

This course is part of the hashi-training project and is licensed under the MIT License.

---

## 🙏 Acknowledgments

- HashiCorp for creating Terraform
- The Libvirt community
- All contributors and learners who help improve this course

---

**Ready to begin?** Start with [TF-101: Introduction to IaC & Terraform Basics](TF-101-intro-basics/README.md)

**Questions?** Check the [FAQ](../docs/faq.md) or [Quick Start Guide](../docs/quick-start-guide.md)

---

*Last Updated: 2026-02-26*  
*Course Version: 3.0*  
*Terraform Version: 1.14+*

---

## 📦 Supplemental Content

The following topics were added after the initial course release to cover additional real-world patterns:

### TF-101 Additions
| Topic | Directory | Description |
|-------|-----------|-------------|
| `null_resource` vs `terraform_data` | `TF-101-intro-basics/terraform-data/` | Legacy `null_resource` pattern vs modern `terraform_data` (1.4+) |
| `local-exec` provisioner | `TF-101-intro-basics/terraform-data/` | When to use local-exec and anti-pattern warnings |

### TF-102 Additions
| Topic | Directory | Description |
|-------|-----------|-------------|
| `for` expressions | `TF-102-variables-loops/5-for-expressions/` | List/map comprehensions with filtering — distinct from `for_each` |

### TF-104 Additions
| Topic | Directory | Description |
|-------|-----------|-------------|
| `terraform console` | `TF-104-state-cli/terraform-console/` | Interactive REPL for testing functions and exploring state |

---

*Last Updated: 2026-02-28*