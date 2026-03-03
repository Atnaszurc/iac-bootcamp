# PKR-100: Packer Fundamentals

**Level**: 100 (Beginner)  
**Duration**: 4 hours  
**Prerequisites**: None (TF-101 recommended but not required)  
**Platform**: QEMU/Libvirt (local image building)

---

## 🎯 Course Overview

Welcome to **PKR-100: Packer Fundamentals**! This course teaches you how to automate the creation of machine images using HashiCorp Packer. Learn to build **golden images** that are consistent, secure, and ready to deploy, eliminating the "works on my machine" problem.

Packer complements Terraform perfectly: **Packer builds images, Terraform deploys them**. Together, they form a complete Infrastructure as Code solution.

---

## 📚 What You'll Learn

### Core Competencies

After completing PKR-100, you will be able to:

- ✅ **Understand Image Building**: Grasp why golden images matter and when to use them
- ✅ **Create Packer Templates**: Write HCL2 templates for image builds
- ✅ **Use QEMU Builder**: Build images for Libvirt/KVM environments
- ✅ **Configure with Provisioners**: Use shell, PowerShell, and Ansible provisioners
- ✅ **Integrate with Ansible**: Leverage Ansible for complex configuration management
- ✅ **Version Images**: Implement image versioning and metadata
- ✅ **Integrate with Terraform**: Use Packer images in Terraform deployments

---

## 🗂️ Course Modules

### PKR-101: Introduction to Image Building
**Duration**: 1 hour  
**Directory**: `PKR-101-intro/`

Learn the fundamentals of image building with Packer. Understand why golden images are important and how Packer automates image creation.

**Topics**:
- What is Packer and why use it?
- Golden image concepts and benefits
- Packer vs configuration management
- Packer architecture (builders, provisioners, communicators)
- QEMU builder for Libvirt
- Packer workflow (validate → build → test)
- HCL2 template syntax

**Hands-On**:
- Install Packer
- Create your first Packer template
- Build a basic Ubuntu image
- Test the image with Terraform
- Understand the build process
- Explore build artifacts

**Key Skills**:
- Image building concepts
- Packer workflow
- Basic template creation
- QEMU builder basics

---

### PKR-102: QEMU Builder & Provisioners
**Duration**: 1 hour  
**Directory**: `PKR-102-qemu-provisioners/`

Master the QEMU builder for creating Libvirt-compatible images. Learn how to use shell and file provisioners to configure images during the build process.

**Topics**:
- QEMU builder configuration
- ISO sources and checksums
- Boot commands and automation
- Shell provisioner for Linux
- PowerShell provisioner for Windows
- File provisioner for copying files
- Build optimization techniques
- Error handling and debugging
- Image testing strategies

**Hands-On**:
- Configure QEMU builder for Ubuntu
- Use shell provisioner for package installation
- Copy files with file provisioner
- Optimize build time
- Handle provisioner failures
- Test built images
- Debug build issues

**Key Skills**:
- QEMU builder configuration
- Shell provisioning
- File management
- Build optimization
- Troubleshooting

---

### PKR-103: Ansible Configuration Management
**Duration**: 1.5 hours  
**Directory**: `PKR-103-ansible/`

Use Ansible with Packer for sophisticated image configuration. Learn how to integrate Ansible playbooks into your image builds for complex configuration management.

**Topics**:
- Ansible provisioner setup
- Writing playbooks for image builds
- Using Ansible roles
- Managing dependencies
- Handling secrets securely
- Testing Ansible configurations
- When to use Ansible vs shell
- Best practices for image configuration

**Hands-On**:
- Set up Ansible provisioner
- Create Ansible playbook for web server
- Build database server image with Ansible
- Use Ansible roles in Packer
- Handle secrets with Ansible Vault
- Test Ansible configurations
- Compare shell vs Ansible approaches

**Key Skills**:
- Ansible provisioner usage
- Playbook development
- Role integration
- Secret management
- Configuration testing

---

### PKR-104: Image Versioning & HCP Packer
**Duration**: 0.5 hours  
**Directory**: `PKR-104-versioning-hcp/`

Implement image versioning strategies and learn about HCP Packer for enterprise image management.

**Topics**:
- Image versioning strategies
- Semantic versioning for images
- Image tagging and metadata
- HCP Packer overview (theoretical)
- Image registry concepts
- Image lifecycle management
- Integration with Terraform
- CI/CD for image builds

**Hands-On**:
- Implement image versioning
- Add metadata to images
- Tag images appropriately
- Integrate versioned images with Terraform
- Plan image lifecycle strategy

**Key Skills**:
- Image versioning
- Metadata management
- Terraform integration
- Lifecycle planning

---

## 🎓 Learning Path

### Recommended Progression

```
Week 1: Packer Basics
├── Day 1: PKR-101 (Introduction to Image Building)
├── Day 2: PKR-102 (QEMU Builder & Provisioners)
└── Day 3-4: PKR-103 (Ansible Configuration Management)

Week 2: Integration
└── Day 1: PKR-104 (Image Versioning & HCP Packer)
    └── Practice: Build complete image pipeline
```

### Parallel Learning

PKR-100 can be taken:
- **Alongside TF-100**: Learn both tools together
- **After TF-100**: Understand Terraform first, then add Packer
- **Standalone**: Focus on image building independently

### Time Commitment

- **Self-Paced**: 4 hours of core content
- **With Practice**: 6-8 hours (recommended)
- **Full Mastery**: 10-12 hours (includes experimentation)

---

## 🚀 Getting Started

### Prerequisites

Before starting PKR-100, ensure you have:

1. **System Requirements**:
   - Linux, macOS, or Windows 10/11 with WSL2
   - 8 GB RAM minimum (16 GB recommended)
   - 100 GB free disk space (for image builds)
   - CPU with virtualization support (Intel VT-x or AMD-V)

2. **Software Installed**:
   - Packer 1.14+ ([installation guide](https://www.packer.io/downloads))
   - QEMU/Libvirt ([installation guide](../docs/libvirt-setup.md))
   - Ansible (for PKR-103)
   - Terraform (optional, for testing images)

3. **Knowledge**:
   - Basic command-line usage
   - Basic understanding of virtual machines
   - Basic Linux administration (helpful but not required)
   - No prior Packer experience needed!

### Quick Start

```bash
# 1. Install Packer
# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install packer

# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/packer

# 2. Verify installation
packer version

# 3. Navigate to the course directory
cd hashi-training/PKR-100-fundamentals

# 4. Start with PKR-101
cd PKR-101-intro
cat README.md
```

---

## 📖 Course Materials

### What's Included

Each module contains:

- **README.md**: Detailed explanations and learning objectives
- **example/**: Working Packer templates
- **Exercises**: Hands-on labs to practice concepts
- **Scripts**: Helper scripts for builds
- **Best Practices**: Industry-standard patterns

### Directory Structure

```
PKR-100-fundamentals/
├── README.md                          # This file
├── PKR-101-intro/
│   ├── README.md                      # Module guide
│   └── example/                       # Basic templates
├── PKR-102-qemu-provisioners/
│   ├── README.md                      # Module guide
│   └── example/                       # QEMU examples
├── PKR-103-ansible/
│   ├── README.md                      # Module guide
│   ├── example/                       # Ansible examples
│   └── playbooks/                     # Sample playbooks
└── PKR-104-versioning-hcp/
    ├── README.md                      # Module guide
    └── example/                       # Versioning examples
```

---

## 🎯 Learning Objectives

### By Module

#### After PKR-101, you will:
- Understand what Packer is and why use it
- Know golden image concepts and benefits
- Understand Packer architecture
- Create basic Packer templates
- Build your first image
- Test images with Terraform

#### After PKR-102, you will:
- Configure QEMU builder for Libvirt
- Use shell provisioners effectively
- Use file provisioners for copying files
- Optimize build times
- Handle build failures
- Debug Packer builds

#### After PKR-103, you will:
- Configure Ansible provisioner
- Write Ansible playbooks for images
- Use Ansible roles in Packer
- Handle secrets securely
- Test Ansible configurations
- Choose between shell and Ansible

#### After PKR-104, you will:
- Implement image versioning
- Add metadata to images
- Understand HCP Packer concepts
- Integrate images with Terraform
- Plan image lifecycle strategies

---

## 🏆 Success Criteria

You've successfully completed PKR-100 when you can:

- [ ] Explain why golden images are important
- [ ] Write Packer templates from scratch
- [ ] Build images using QEMU builder
- [ ] Use shell and Ansible provisioners
- [ ] Version images appropriately
- [ ] Integrate Packer images with Terraform
- [ ] Debug build failures
- [ ] Optimize build times
- [ ] Handle secrets securely

---

## 🔄 What's Next?

### After PKR-100

Once you complete PKR-100, you're ready for:

1. **Integrate with Terraform**
   - Use Packer images in TF-100 exercises
   - Build complete infrastructure pipelines
   - Implement immutable infrastructure

2. **Cloud Provider Images**
   - Build AWS AMIs
   - Build Azure images
   - Build GCP images
   - Multi-cloud image strategies

3. **Advanced Topics**:
   - CI/CD for image builds
   - Image testing strategies
   - HCP Packer (enterprise)
   - Multi-architecture builds

4. **Real-World Projects**:
   - Build golden images for your organization
   - Create image pipelines
   - Implement security hardening
   - Automate image updates

---

## 💡 Tips for Success

### Best Practices

1. **Start Simple**: Begin with basic shell provisioners before Ansible
2. **Test Frequently**: Build and test images often during development
3. **Version Everything**: Always version your images
4. **Document Images**: Include metadata about what's in each image
5. **Automate Builds**: Use CI/CD for consistent image creation

### Common Pitfalls to Avoid

- ❌ Building monolithic images (too much in one image)
- ❌ Not versioning images
- ❌ Hardcoding secrets in templates
- ❌ Not testing images before deployment
- ❌ Ignoring build optimization
- ❌ Not documenting image contents

### Image Building Principles

1. **Immutability**: Images should be immutable once built
2. **Minimal**: Include only what's necessary
3. **Secure**: Harden images during build
4. **Tested**: Test images before deployment
5. **Versioned**: Always version images
6. **Documented**: Document what's in each image

---

## 📚 Additional Resources

### Official Documentation

- [Packer Documentation](https://www.packer.io/docs)
- [QEMU Builder](https://www.packer.io/docs/builders/qemu)
- [Ansible Provisioner](https://www.packer.io/docs/provisioners/ansible)
- [HCP Packer](https://cloud.hashicorp.com/products/packer)

### Recommended Reading

- [Packer Best Practices](https://www.packer.io/guides/packer-on-cicd)
- [Golden Image Pipeline](https://www.hashicorp.com/resources/golden-image-pipeline)
- [Immutable Infrastructure](https://www.hashicorp.com/resources/what-is-mutable-vs-immutable-infrastructure)

### Community

- [Packer GitHub](https://github.com/hashicorp/packer)
- [HashiCorp Community Forum](https://discuss.hashicorp.com/c/packer)
- [Packer Templates](https://github.com/topics/packer-templates)

---

## 🐛 Troubleshooting

### Common Issues

**Build Failures**:
```bash
# Enable debug logging
export PACKER_LOG=1
packer build template.pkr.hcl

# Validate template first
packer validate template.pkr.hcl
```

**QEMU Issues**:
```bash
# Check QEMU installation
qemu-system-x86_64 --version

# Verify virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo
```

**Provisioner Failures**:
```bash
# Test provisioner scripts independently
# before adding to Packer template

# Use -on-error=ask to debug
packer build -on-error=ask template.pkr.hcl
```

**Ansible Issues**:
```bash
# Test playbook independently
ansible-playbook -i localhost, playbook.yml

# Check Ansible version compatibility
ansible --version
```

For detailed troubleshooting, see:
- Module-specific README files
- [Packer Debugging Guide](https://www.packer.io/docs/debugging)

---

## 📊 Course Statistics

- **Total Modules**: 4
- **Hands-On Labs**: 15+
- **Code Examples**: 25+
- **Image Templates**: 10+
- **Estimated Completion**: 4-12 hours

---

## 🎓 Real-World Applications

### What You Can Build

After PKR-100, you can:

- **Golden Images**: Standardized, pre-configured images
- **Security-Hardened Images**: CIS-compliant base images
- **Application Images**: Images with pre-installed applications
- **Development Environments**: Consistent dev environments
- **CI/CD Pipelines**: Automated image building
- **Multi-Cloud Images**: Images for multiple providers

### Industry Use Cases

- **Enterprises**: Standardized images across teams
- **Startups**: Fast, consistent deployments
- **DevOps Teams**: Immutable infrastructure
- **Security Teams**: Hardened, compliant images
- **Platform Teams**: Self-service image catalogs

---

## 🔗 Integration with Terraform

### Packer + Terraform Workflow

```
1. Packer: Build golden image
   └── Creates: image.qcow2

2. Terraform: Deploy infrastructure
   └── Uses: image.qcow2
   └── Creates: VMs from image

3. Result: Fast, consistent deployments
```

### Example Integration

```hcl
# Packer builds the image
# packer build ubuntu-web.pkr.hcl

# Terraform uses the image
resource "libvirt_volume" "web" {
  name   = "web-server"
  source = "/var/lib/libvirt/images/ubuntu-web-v1.0.0.qcow2"
}

resource "libvirt_domain" "web" {
  name   = "web-server"
  memory = "2048"
  vcpu   = 2

  disk {
    volume_id = libvirt_volume.web.id
  }
}
```

---

## 🤝 Contributing

Found an issue or want to improve the course?

- Report bugs via GitHub Issues
- Suggest improvements via Pull Requests
- Share your Packer templates
- Help other learners in Discussions

---

## 📜 License

This course is part of the hashi-training project and is licensed under the MIT License.

---

## 🙏 Acknowledgments

- HashiCorp for creating Packer
- The QEMU/Libvirt community
- Ansible community
- All contributors who help improve this course

---

**Ready to begin?** Start with [PKR-101: Introduction to Image Building](PKR-101-intro/README.md)

**Want to learn Terraform first?** Check out [TF-100: Terraform Fundamentals](../TF-100-fundamentals/README.md)

**Questions?** Check the [Course Catalog](../docs/course-catalog.md) or [FAQ](../docs/faq.md)

---

*Last Updated: 2026-02-26*  
*Course Version: 3.0*  
*Packer Version: 1.14+*

---

## 📦 Supplemental Content

The following topics were added after the initial course release to cover additional real-world patterns:

### PKR-102 Additions
| Topic | Directory | Description |
|-------|-----------|-------------|
| Post-processors | `PKR-102-qemu-provisioners/post-processors/` | `shell-local` and `manifest` post-processors for build pipelines |

### PKR-103 Additions
| Topic | Directory | Description |
|-------|-----------|-------------|
| Packer variables | `PKR-103-ansible/packer-variables/` | `variable` blocks, `.pkrvars.hcl` files, `locals`, sensitive values, precedence |

---

*Last Updated: 2026-02-28*