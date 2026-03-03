# PKR-101: Introduction to Image Building

**Course**: PKR-100 Packer Fundamentals  
**Module**: PKR-101  
**Duration**: 1 hour  
**Prerequisites**: None (can be taken alongside TF-100)  
**Packer Version**: 1.14+

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [What is Packer?](#what-is-packer)
4. [Why Use Packer?](#why-use-packer)
5. [Packer vs Other Tools](#packer-vs-other-tools)
6. [Core Concepts](#core-concepts)
7. [Packer Architecture](#packer-architecture)
8. [Installation and Setup](#installation-and-setup)
9. [Your First Packer Template](#your-first-packer-template)
10. [Packer File Structure](#packer-file-structure)
11. [Basic Packer Commands](#basic-packer-commands)
12. [Image Building Workflow](#image-building-workflow)
13. [Golden Images Explained](#golden-images-explained)
14. [Best Practices](#best-practices)
15. [Hands-On Labs](#hands-on-labs)
16. [Checkpoint Quiz](#checkpoint-quiz)
17. [Additional Resources](#additional-resources)

---

## Course Overview

This course introduces HashiCorp Packer, a tool for creating identical machine images for multiple platforms from a single source configuration. You'll learn the fundamentals of image building and create your first VM image using QEMU.

### What You'll Build

- Your first Packer template
- A basic Ubuntu VM image
- Understanding of image building workflow
- Foundation for advanced Packer features

### Why This Matters

- **Consistency**: Identical images across environments
- **Speed**: Pre-configured images deploy faster
- **Reliability**: Tested, validated images
- **Automation**: Infrastructure as Code for images
- **Portability**: Same config, multiple platforms

---

## Learning Objectives

By the end of this course, you will be able to:

1. ✅ Explain what Packer is and why it's used
2. ✅ Understand the image building workflow
3. ✅ Install and configure Packer
4. ✅ Write basic Packer templates (HCL2)
5. ✅ Build VM images with QEMU
6. ✅ Use Packer CLI commands
7. ✅ Understand golden image concepts
8. ✅ Apply image building best practices

---

## What is Packer?

### Definition

**HashiCorp Packer** is an open-source tool for creating identical machine images for multiple platforms from a single source configuration.

### Key Features

- **Multi-Platform**: Build images for multiple platforms simultaneously
- **Automated**: Fully automated image creation
- **Declarative**: Define images as code (HCL2)
- **Parallel Builds**: Build multiple images concurrently
- **Provisioners**: Configure images with shell, Ansible, Chef, etc.
- **Post-Processors**: Compress, upload, or transform images

### What Packer Does

```
Source Image → Packer Template → Provisioning → Output Image
(Base OS)      (Configuration)    (Customize)    (Golden Image)
```

### What Packer Doesn't Do

❌ **Not a Configuration Management Tool**: Use Ansible/Chef/Puppet for that  
❌ **Not a Deployment Tool**: Use Terraform for infrastructure deployment  
❌ **Not a Container Builder**: Use Docker/Buildah for containers  
❌ **Not a VM Manager**: Use Terraform/Vagrant for VM management

---

## Why Use Packer?

### The Problem Without Packer

**Manual Image Creation**:
- ❌ Time-consuming (hours per image)
- ❌ Error-prone (human mistakes)
- ❌ Inconsistent (different each time)
- ❌ Undocumented (tribal knowledge)
- ❌ Not reproducible (can't recreate exactly)

**Deployment-Time Configuration**:
- ❌ Slow deployments (install packages at boot)
- ❌ Network dependencies (download during boot)
- ❌ Failure points (package repos down)
- ❌ Inconsistent state (different versions)

### The Solution With Packer

**Automated Image Building**:
- ✅ Fast (minutes, automated)
- ✅ Consistent (same every time)
- ✅ Documented (code is documentation)
- ✅ Reproducible (version controlled)
- ✅ Testable (validate before use)

**Pre-Configured Images**:
- ✅ Fast deployments (boot and run)
- ✅ No network dependencies (everything pre-installed)
- ✅ Fewer failure points (tested images)
- ✅ Consistent state (known configuration)

### Use Cases

1. **Development Environments**: Consistent dev machines
2. **CI/CD Pipelines**: Pre-configured build agents
3. **Production Deployments**: Immutable infrastructure
4. **Disaster Recovery**: Quick recovery with known-good images
5. **Multi-Cloud**: Same image across providers
6. **Security**: Hardened, patched base images

---

## Packer vs Other Tools

### Packer vs Docker

| Aspect | Packer | Docker |
|--------|--------|--------|
| **Purpose** | VM images | Container images |
| **Output** | Full OS image | Application layer |
| **Boot Time** | Minutes | Seconds |
| **Isolation** | Full VM | Process isolation |
| **Use Case** | Infrastructure | Applications |

### Packer vs Vagrant

| Aspect | Packer | Vagrant |
|--------|--------|--------|
| **Purpose** | Build images | Manage VMs |
| **Focus** | Image creation | Development environments |
| **Output** | Image files | Running VMs |
| **Workflow** | Build once | Use many times |

### Packer vs Terraform

| Aspect | Packer | Terraform |
|--------|--------|--------|
| **Purpose** | Build images | Deploy infrastructure |
| **Focus** | Image creation | Resource management |
| **When** | Before deployment | During deployment |
| **Output** | Images | Running infrastructure |

### The Complete Workflow

```
1. Packer: Build golden images
   ↓
2. Terraform: Deploy infrastructure using images
   ↓
3. Ansible: Configure running systems (if needed)
```

---

## Core Concepts

### 1. Templates

**Definition**: Configuration files defining how to build images

```hcl
# example.pkr.hcl
packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1.0"
    }
  }
}

source "qemu" "ubuntu" {
  # Source configuration
}

build {
  sources = ["source.qemu.ubuntu"]
  # Build steps
}
```

### 2. Builders

**Definition**: Platform-specific plugins that create images

**Common Builders**:
- `qemu`: QEMU/KVM (local VMs)
- `amazon-ebs`: AWS AMIs
- `azure-arm`: Azure images
- `googlecompute`: GCP images
- `docker`: Docker images
- `virtualbox-iso`: VirtualBox images

### 3. Provisioners

**Definition**: Tools that configure images during build

**Common Provisioners**:
- `shell`: Run shell scripts
- `file`: Copy files
- `ansible`: Run Ansible playbooks
- `chef`: Run Chef recipes
- `puppet`: Run Puppet manifests

### 4. Post-Processors

**Definition**: Tools that process images after build

**Common Post-Processors**:
- `compress`: Compress images
- `checksum`: Generate checksums
- `manifest`: Create manifest files
- `shell-local`: Run local commands

### 5. Variables

**Definition**: Parameterize templates for flexibility

```hcl
variable "vm_name" {
  type    = string
  default = "ubuntu-base"
}

variable "memory" {
  type    = number
  default = 2048
}
```

---

## Packer Architecture

### Build Process Flow

```
┌─────────────────┐
│  Packer CLI     │
│  (packer build) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Template       │
│  (.pkr.hcl)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Builder        │
│  (QEMU)         │
│  - Start VM     │
│  - Boot ISO     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Provisioners   │
│  - Shell        │
│  - Ansible      │
│  - File         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Post-Process   │
│  - Compress     │
│  - Checksum     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Output Image   │
│  (QCOW2 file)   │
└─────────────────┘
```

### Plugin System

Packer uses a plugin architecture:

```
Packer Core
    ├── Builder Plugins (qemu, amazon-ebs, etc.)
    ├── Provisioner Plugins (shell, ansible, etc.)
    └── Post-Processor Plugins (compress, checksum, etc.)
```

---

## Installation and Setup

### Installing Packer

**Linux (Ubuntu/Debian)**:
```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Packer
sudo apt update && sudo apt install packer
```

**macOS (Homebrew)**:
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/packer
```

**Windows (Chocolatey)**:
```powershell
choco install packer
```

**Manual Installation**:
```bash
# Download from https://www.packer.io/downloads
# Extract and move to PATH
wget https://releases.hashicorp.com/packer/1.10.0/packer_1.10.0_linux_amd64.zip
unzip packer_1.10.0_linux_amd64.zip
sudo mv packer /usr/local/bin/
```

### Verify Installation

```bash
packer version
# Output: Packer v1.10.0
```

### Installing QEMU (Required for Labs)

**Linux**:
```bash
sudo apt install qemu-system-x86 qemu-utils
```

**macOS**:
```bash
brew install qemu
```

**Verify QEMU**:
```bash
qemu-system-x86_64 --version
```

---

## Your First Packer Template

### Minimal Template

**File**: `first-image.pkr.hcl`

```hcl
# Packer configuration block
packer {
  required_version = ">= 1.14.0"
  
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1.0"
    }
  }
}

# Variables
variable "vm_name" {
  type    = string
  default = "ubuntu-base"
}

# Source block (builder configuration)
source "qemu" "ubuntu" {
  # VM settings
  vm_name        = var.vm_name
  memory         = 2048
  cpus           = 2
  disk_size      = "10G"
  
  # ISO settings
  iso_url      = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
  iso_checksum = "sha256:a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"
  
  # Output settings
  output_directory = "output-ubuntu"
  format           = "qcow2"
  
  # Boot settings
  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "linux /casper/vmlinuz autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<enter>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]
  
  # HTTP server for autoinstall
  http_directory = "http"
  
  # SSH settings
  ssh_username     = "ubuntu"
  ssh_password     = "ubuntu"
  ssh_timeout      = "20m"
  shutdown_command = "echo 'ubuntu' | sudo -S shutdown -P now"
}

# Build block
build {
  sources = ["source.qemu.ubuntu"]
  
  # Simple provisioner
  provisioner "shell" {
    inline = [
      "echo 'Hello from Packer!'",
      "sudo apt-get update",
      "sudo apt-get install -y vim curl"
    ]
  }
}
```

### Understanding the Template

**1. Packer Block**: Specifies Packer version and required plugins  
**2. Variables**: Parameterize the template  
**3. Source Block**: Defines how to build the image (builder config)  
**4. Build Block**: Orchestrates the build process with provisioners

---

## Packer File Structure

### Recommended Directory Structure

```
packer-project/
├── builds/
│   ├── ubuntu.pkr.hcl          # Ubuntu image template
│   ├── debian.pkr.hcl          # Debian image template
│   └── alpine.pkr.hcl          # Alpine image template
├── http/
│   ├── user-data               # Cloud-init config
│   └── meta-data               # Cloud-init metadata
├── scripts/
│   ├── setup.sh                # Setup script
│   ├── cleanup.sh              # Cleanup script
│   └── hardening.sh            # Security hardening
├── variables/
│   ├── common.pkrvars.hcl      # Common variables
│   ├── dev.pkrvars.hcl         # Dev environment
│   └── prod.pkrvars.hcl        # Prod environment
├── output/                      # Build output (gitignored)
└── README.md                    # Documentation
```

### File Naming Conventions

- **Templates**: `<os-name>.pkr.hcl` (e.g., `ubuntu.pkr.hcl`)
- **Variables**: `<env>.pkrvars.hcl` (e.g., `prod.pkrvars.hcl`)
- **Scripts**: `<purpose>.sh` (e.g., `setup.sh`)

---

## Basic Packer Commands

### Initialize Packer

```bash
# Download required plugins
packer init .

# Initialize specific template
packer init ubuntu.pkr.hcl
```

### Validate Template

```bash
# Validate syntax and configuration
packer validate ubuntu.pkr.hcl

# Validate with variables
packer validate -var-file=prod.pkrvars.hcl ubuntu.pkr.hcl
```

### Format Template

```bash
# Format HCL files
packer fmt ubuntu.pkr.hcl

# Format all files in directory
packer fmt .

# Check if formatting is needed
packer fmt -check .
```

### Build Image

```bash
# Build image
packer build ubuntu.pkr.hcl

# Build with variables
packer build -var-file=prod.pkrvars.hcl ubuntu.pkr.hcl

# Build with inline variables
packer build -var 'vm_name=my-ubuntu' ubuntu.pkr.hcl

# Build specific source only
packer build -only='qemu.ubuntu' ubuntu.pkr.hcl

# Debug mode
packer build -debug ubuntu.pkr.hcl

# Force rebuild (ignore cache)
packer build -force ubuntu.pkr.hcl
```

### Inspect Template

```bash
# Show template information
packer inspect ubuntu.pkr.hcl
```

### Console (REPL)

```bash
# Interactive console for testing expressions
packer console ubuntu.pkr.hcl

# Example usage:
> var.vm_name
"ubuntu-base"

> upper(var.vm_name)
"UBUNTU-BASE"
```

---

## Image Building Workflow

### Step-by-Step Process

```
1. Write Template
   ├── Define variables
   ├── Configure source (builder)
   └── Add provisioners

2. Initialize
   └── packer init template.pkr.hcl

3. Validate
   └── packer validate template.pkr.hcl

4. Build
   └── packer build template.pkr.hcl

5. Test Image
   ├── Boot VM from image
   ├── Verify configuration
   └── Run tests

6. Deploy
   └── Use image with Terraform/Libvirt
```

### Build Output Example

```bash
$ packer build ubuntu.pkr.hcl

qemu.ubuntu: output will be in this color.

==> qemu.ubuntu: Retrieving ISO
==> qemu.ubuntu: Trying https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso
==> qemu.ubuntu: Starting HTTP server on port 8000
==> qemu.ubuntu: Starting VM
==> qemu.ubuntu: Waiting for SSH to become available...
==> qemu.ubuntu: Connected to SSH!
==> qemu.ubuntu: Provisioning with shell script: /tmp/packer-shell123456
    qemu.ubuntu: Hello from Packer!
    qemu.ubuntu: Reading package lists...
    qemu.ubuntu: Building dependency tree...
==> qemu.ubuntu: Gracefully halting virtual machine...
==> qemu.ubuntu: Converting hard drive...
Build 'qemu.ubuntu' finished after 15 minutes 32 seconds.

==> Wait completed after 15 minutes 32 seconds

==> Builds finished. The artifacts of successful builds are:
--> qemu.ubuntu: VM files in directory: output-ubuntu
```

---

## Golden Images Explained

### What is a Golden Image?

A **golden image** is a pre-configured, tested, and approved machine image that serves as a template for creating new VMs.

### Characteristics

- ✅ **Fully Configured**: All software pre-installed
- ✅ **Tested**: Validated before use
- ✅ **Hardened**: Security best practices applied
- ✅ **Documented**: Known configuration
- ✅ **Versioned**: Tracked changes
- ✅ **Immutable**: Not modified after creation

### Golden Image Layers

```
┌─────────────────────────────┐
│  Application Layer          │  ← App-specific config
├─────────────────────────────┤
│  Organization Layer         │  ← Company standards
├─────────────────────────────┤
│  Security Layer             │  ← Hardening, patches
├─────────────────────────────┤
│  Base OS Layer              │  ← Ubuntu/Debian/Alpine
└─────────────────────────────┘
```

### Golden Image Lifecycle

```
1. Build → 2. Test → 3. Approve → 4. Deploy → 5. Monitor
    ↑                                              ↓
    └──────────────── 6. Update ←─────────────────┘
```

### Benefits

1. **Consistency**: Same configuration everywhere
2. **Speed**: Fast deployments (no install time)
3. **Reliability**: Tested, known-good state
4. **Security**: Patched, hardened images
5. **Compliance**: Meet regulatory requirements

---

## Best Practices

### 1. Version Your Images

```hcl
variable "image_version" {
  type    = string
  default = "1.0.0"
}

source "qemu" "ubuntu" {
  vm_name = "ubuntu-${var.image_version}"
}
```

### 2. Use Variables for Flexibility

```hcl
# ❌ Bad: Hard-coded values
source "qemu" "ubuntu" {
  memory = 2048
  cpus   = 2
}

# ✅ Good: Parameterized
variable "memory" {
  type    = number
  default = 2048
}

variable "cpus" {
  type    = number
  default = 2
}

source "qemu" "ubuntu" {
  memory = var.memory
  cpus   = var.cpus
}
```

### 3. Keep Images Small

```bash
# Remove unnecessary packages
sudo apt-get autoremove -y
sudo apt-get clean

# Clear caches
sudo rm -rf /var/cache/apt/archives/*
sudo rm -rf /tmp/*

# Zero out free space (for compression)
sudo dd if=/dev/zero of=/EMPTY bs=1M || true
sudo rm -f /EMPTY
```

### 4. Document Your Images

```hcl
# ubuntu-base.pkr.hcl
# Purpose: Base Ubuntu 22.04 image for web servers
# Includes: nginx, certbot, monitoring agents
# Version: 1.0.0
# Last Updated: 2026-02-26
# Maintainer: DevOps Team

packer {
  # ...
}
```

### 5. Test Images Before Use

```bash
# Boot image and test
qemu-system-x86_64 \
  -m 2048 \
  -smp 2 \
  -drive file=output-ubuntu/ubuntu-base,format=qcow2 \
  -nographic
```

### 6. Use Checksums

```hcl
source "qemu" "ubuntu" {
  iso_url      = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
  iso_checksum = "sha256:a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"
}
```

---

## Hands-On Labs

### Lab 1: Install Packer and Build First Image (30 minutes)

**Objective**: Install Packer, QEMU, and build your first VM image

**Tasks**:
1. Install Packer and QEMU
2. Create a minimal Packer template
3. Initialize and validate the template
4. Build a basic Ubuntu image
5. Verify the output image

**Starter Template** (`minimal.pkr.hcl`):
```hcl
packer {
  required_version = ">= 1.14.0"
  
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1.0"
    }
  }
}

source "qemu" "minimal" {
  vm_name      = "minimal-ubuntu"
  memory       = 1024
  cpus         = 1
  disk_size    = "5G"
  format       = "qcow2"
  
  iso_url      = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
  iso_checksum = "sha256:a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"
  
  output_directory = "output-minimal"
  
  # Simplified boot (manual installation)
  boot_wait = "5s"
  
  ssh_username = "ubuntu"
  ssh_password = "ubuntu"
  ssh_timeout  = "20m"
  
  shutdown_command = "echo 'ubuntu' | sudo -S shutdown -P now"
}

build {
  sources = ["source.qemu.minimal"]
  
  provisioner "shell" {
    inline = [
      "echo 'Image built successfully!'",
      "uname -a"
    ]
  }
}
```

**Your Task**:
1. Install Packer and QEMU
2. Create the template file
3. Run `packer init minimal.pkr.hcl`
4. Run `packer validate minimal.pkr.hcl`
5. Run `packer build minimal.pkr.hcl`
6. Verify output in `output-minimal/` directory

**Expected Result**:
```bash
$ ls -lh output-minimal/
total 1.2G
-rw-r--r-- 1 user user 1.2G Feb 26 22:00 minimal-ubuntu
```

---

### Lab 2: Parameterize Your Template (20 minutes)

**Objective**: Add variables and create multiple image variants

**Tasks**:
1. Add variables to your template
2. Create variable files for different environments
3. Build images with different configurations
4. Compare output images

**Enhanced Template** (`parameterized.pkr.hcl`):
```hcl
variable "vm_name" {
  type        = string
  description = "Name of the VM"
}

variable "memory" {
  type        = number
  description = "Memory in MB"
  default     = 2048
}

variable "cpus" {
  type        = number
  description = "Number of CPUs"
  default     = 2
}

variable "disk_size" {
  type        = string
  description = "Disk size"
  default     = "10G"
}

source "qemu" "ubuntu" {
  vm_name   = var.vm_name
  memory    = var.memory
  cpus      = var.cpus
  disk_size = var.disk_size
  
  # ... rest of configuration
}
```

**Variable Files**:

`small.pkrvars.hcl`:
```hcl
vm_name   = "ubuntu-small"
memory    = 1024
cpus      = 1
disk_size = "5G"
```

`large.pkrvars.hcl`:
```hcl
vm_name   = "ubuntu-large"
memory    = 4096
cpus      = 4
disk_size = "20G"
```

**Your Task**:
1. Create the parameterized template
2. Create variable files for small and large VMs
3. Build both variants
4. Compare the output images

**Expected Result**:
```bash
$ packer build -var-file=small.pkrvars.hcl parameterized.pkr.hcl
$ packer build -var-file=large.pkrvars.hcl parameterized.pkr.hcl

$ ls -lh output-*/
output-ubuntu-small/:
total 1.0G
-rw-r--r-- 1 user user 1.0G Feb 26 22:10 ubuntu-small

output-ubuntu-large/:
total 1.5G
-rw-r--r-- 1 user user 1.5G Feb 26 22:20 ubuntu-large
```

---

### Lab 3: Add Provisioning (25 minutes)

**Objective**: Use provisioners to customize your image

**Tasks**:
1. Add shell provisioner to install packages
2. Add file provisioner to copy configuration
3. Add cleanup provisioner
4. Build and test the customized image

**Template with Provisioners** (`provisioned.pkr.hcl`):
```hcl
build {
  sources = ["source.qemu.ubuntu"]
  
  # Update system
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y"
    ]
  }
  
  # Install packages
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y vim curl wget git",
      "sudo apt-get install -y htop net-tools"
    ]
  }
  
  # Copy configuration file
  provisioner "file" {
    source      = "configs/motd"
    destination = "/tmp/motd"
  }
  
  # Apply configuration
  provisioner "shell" {
    inline = [
      "sudo mv /tmp/motd /etc/motd",
      "sudo chmod 644 /etc/motd"
    ]
  }
  
  # Cleanup
  provisioner "shell" {
    inline = [
      "sudo apt-get autoremove -y",
      "sudo apt-get clean",
      "sudo rm -rf /tmp/*"
    ]
  }
}
```

**Your Task**:
1. Create the template with provisioners
2. Create a custom MOTD file in `configs/motd`
3. Build the image
4. Boot the image and verify customizations

**Expected Result**:
```bash
$ qemu-system-x86_64 -m 2048 -drive file=output-ubuntu/ubuntu-base,format=qcow2 -nographic

# After boot, you should see your custom MOTD
# Installed packages should be available
$ vim --version
$ git --version
```

---

## Checkpoint Quiz

### Question 1: Packer Purpose
**What is the primary purpose of HashiCorp Packer?**

A) Deploy infrastructure  
B) Create identical machine images  
C) Manage containers  
D) Configure running systems

<details>
<summary>Show Answer</summary>

**Answer: B) Create identical machine images**

**Explanation**: Packer is specifically designed to create identical machine images for multiple platforms from a single source configuration. It's not for deploying infrastructure (that's Terraform), managing containers (that's Docker), or configuring running systems (that's Ansible/Chef/Puppet).

</details>

---

### Question 2: Golden Images
**What is a golden image?**

A) An image with gold-colored UI  
B) A pre-configured, tested, approved machine image  
C) An image stored in the cloud  
D) A compressed image file

<details>
<summary>Show Answer</summary>

**Answer: B) A pre-configured, tested, approved machine image**

**Explanation**: A golden image is a fully configured, tested, and approved machine image that serves as a template for creating new VMs. It includes all necessary software, configurations, and security hardening, providing a consistent starting point for deployments.

</details>

---

### Question 3: Packer Components
**Which Packer component is responsible for creating the actual image?**

A) Provisioner  
B) Builder  
C) Post-Processor  
D) Variable

<details>
<summary>Show Answer</summary>

**Answer: B) Builder**

**Explanation**: Builders are platform-specific plugins that create images (e.g., `qemu`, `amazon-ebs`, `azure-arm`). Provisioners configure images during build, post-processors process images after build, and variables parameterize templates.

</details>

---

### Question 4: Packer Commands
**What command initializes Packer and downloads required plugins?**

A) `packer start`  
B) `packer init`  
C) `packer setup`  
D) `packer install`

<details>
<summary>Show Answer</summary>

**Answer: B) `packer init`**

**Explanation**: `packer init` downloads and installs the required plugins specified in the `required_plugins` block of your template. This must be run before building images.

</details>

---

### Question 5: Template Validation
**Which command validates a Packer template without building an image?**

A) `packer check`  
B) `packer test`  
C) `packer validate`  
D) `packer verify`

<details>
<summary>Show Answer</summary>

**Answer: C) `packer validate`**

**Explanation**: `packer validate` checks the syntax and configuration of your template without actually building an image. It's useful for catching errors early in the development process.

</details>

---

### Question 6: Packer vs Terraform
**What is the key difference between Packer and Terraform?**

A) Packer is faster than Terraform  
B) Packer builds images, Terraform deploys infrastructure  
C) Packer is for containers, Terraform is for VMs  
D) Packer is cloud-only, Terraform is local-only

<details>
<summary>Show Answer</summary>

**Answer: B) Packer builds images, Terraform deploys infrastructure**

**Explanation**: Packer creates machine images (the "what"), while Terraform deploys and manages infrastructure (the "where" and "how"). They complement each other: use Packer to build golden images, then use Terraform to deploy VMs from those images.

Typical workflow:
1. Packer: Build golden image
2. Terraform: Deploy VMs using that image
3. Ansible: Configure running systems (if needed)

</details>

---

## Additional Resources

### Official Documentation
- [Packer Documentation](https://www.packer.io/docs)
- [Packer Tutorials](https://learn.hashicorp.com/packer)
- [QEMU Builder](https://www.packer.io/docs/builders/qemu)
- [HCL2 Configuration](https://www.packer.io/guides/hcl)

### Community Resources
- [Packer GitHub](https://github.com/hashicorp/packer)
- [Packer Community Forum](https://discuss.hashicorp.com/c/packer)
- [Example Templates](https://github.com/hashicorp/packer/tree/main/examples)

### Related Tools
- [Terraform](https://www.terraform.io/) - Infrastructure deployment
- [Vagrant](https://www.vagrantup.com/) - Development environments
- [Ansible](https://www.ansible.com/) - Configuration management

### Next Steps
- **PKR-102**: QEMU Builder & Provisioners (detailed builder config)
- **PKR-103**: Ansible Configuration Management (advanced provisioning)
- **PKR-104**: Image Versioning & HCP Packer (image management)

---

## Summary

In this course, you learned:

✅ **What Packer Is**: Tool for creating identical machine images  
✅ **Why Use Packer**: Consistency, speed, reliability, automation  
✅ **Core Concepts**: Templates, builders, provisioners, post-processors  
✅ **Installation**: How to install Packer and QEMU  
✅ **First Template**: Created and built your first image  
✅ **Packer Commands**: init, validate, fmt, build, inspect  
✅ **Golden Images**: Pre-configured, tested, approved images  
✅ **Best Practices**: Versioning, variables, documentation, testing

### Key Takeaways

1. **Packer Builds Images**: Not for deployment or configuration management
2. **Declarative Configuration**: Define images as code (HCL2)
3. **Multi-Platform**: Same config, multiple platforms
4. **Automation**: Fully automated, reproducible builds
5. **Golden Images**: Foundation for consistent infrastructure

### What's Next?

Continue to **PKR-102: QEMU Builder & Provisioners** to learn:
- Detailed QEMU builder configuration
- Advanced provisioning techniques
- Shell and file provisioners
- Building production-ready images

---

**Course**: PKR-100 Packer Fundamentals  
**Module**: PKR-101 - Introduction to Image Building  
**Duration**: 1 hour  
**Last Updated**: 2026-02-26
