# PKR-102: QEMU Builder & Provisioners

**Course**: PKR-100 Packer Fundamentals  
**Module**: PKR-102  
**Duration**: 1 hour  
**Prerequisites**: PKR-101 (Introduction to Image Building)  
**Packer Version**: 1.14+

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [QEMU Builder Deep Dive](#qemu-builder-deep-dive)
4. [QEMU Builder Configuration](#qemu-builder-configuration)
5. [ISO Boot Configuration](#iso-boot-configuration)
6. [Cloud-Init Integration](#cloud-init-integration)
7. [Provisioners Overview](#provisioners-overview)
8. [Shell Provisioner](#shell-provisioner)
9. [File Provisioner](#file-provisioner)
10. [Provisioner Execution Order](#provisioner-execution-order)
11. [Error Handling](#error-handling)
12. [Advanced Provisioning Patterns](#advanced-provisioning-patterns)
13. [Best Practices](#best-practices)
14. [Hands-On Labs](#hands-on-labs)
15. [Checkpoint Quiz](#checkpoint-quiz)
16. [Additional Resources](#additional-resources)

---

## Course Overview

This course provides an in-depth look at the QEMU builder and provisioners in Packer. You'll learn how to configure the QEMU builder for various scenarios and use provisioners to customize your images.

### What You'll Build

- Fully configured QEMU builder templates
- Images with shell provisioning
- Images with file provisioning
- Multi-stage provisioning workflows
- Production-ready image configurations

### Why This Matters

- **Builder Mastery**: Understand QEMU builder options
- **Provisioning Skills**: Customize images effectively
- **Automation**: Fully automated image creation
- **Flexibility**: Handle various use cases
- **Production Ready**: Build enterprise-grade images

---

## Learning Objectives

By the end of this course, you will be able to:

1. ✅ Configure QEMU builder comprehensively
2. ✅ Understand ISO boot processes
3. ✅ Integrate cloud-init for automation
4. ✅ Use shell provisioners effectively
5. ✅ Use file provisioners for configuration
6. ✅ Chain multiple provisioners
7. ✅ Handle provisioning errors
8. ✅ Apply advanced provisioning patterns

---

## QEMU Builder Deep Dive

### What is the QEMU Builder?

The **QEMU builder** creates VM images using QEMU/KVM. It's ideal for:

- ✅ Local development
- ✅ CI/CD pipelines
- ✅ Testing before cloud deployment
- ✅ Creating Libvirt-compatible images
- ✅ Multi-architecture builds

### QEMU Builder Workflow

```
1. Download ISO
   ↓
2. Create disk image
   ↓
3. Start QEMU VM
   ↓
4. Boot from ISO
   ↓
5. Automated installation (cloud-init/preseed)
   ↓
6. Run provisioners
   ↓
7. Shutdown VM
   ↓
8. Convert/compress image
   ↓
9. Output final image
```

### QEMU vs Other Builders

| Feature | QEMU | VirtualBox | VMware |
|---------|------|------------|--------|
| **Cost** | Free | Free | Paid |
| **Performance** | Excellent | Good | Excellent |
| **Linux Support** | Native | Good | Good |
| **Headless** | Yes | Yes | Yes |
| **Formats** | QCOW2, RAW | VDI, VMDK | VMDK |
| **Use Case** | Production | Development | Enterprise |

---

## QEMU Builder Configuration

### Complete Configuration Example

```hcl
source "qemu" "ubuntu" {
  # VM Identification
  vm_name = "ubuntu-22.04-base"
  
  # Hardware Configuration
  memory       = 2048
  cpus         = 2
  disk_size    = "10G"
  disk_interface = "virtio"
  net_device   = "virtio-net"
  
  # ISO Configuration
  iso_url      = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
  iso_checksum = "sha256:a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"
  
  # Output Configuration
  output_directory = "output-ubuntu"
  format           = "qcow2"
  
  # Accelerator (KVM on Linux)
  accelerator = "kvm"
  
  # Display Configuration
  headless = true
  
  # Boot Configuration
  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "linux /casper/vmlinuz autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<enter>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]
  
  # HTTP Server for autoinstall
  http_directory = "http"
  http_port_min  = 8000
  http_port_max  = 8100
  
  # SSH Configuration
  ssh_username     = "ubuntu"
  ssh_password     = "ubuntu"
  ssh_timeout      = "20m"
  ssh_handshake_attempts = 100
  
  # Shutdown Configuration
  shutdown_command = "echo 'ubuntu' | sudo -S shutdown -P now"
  shutdown_timeout = "5m"
  
  # QEMU Arguments (advanced)
  qemuargs = [
    ["-m", "2048M"],
    ["-smp", "2"]
  ]
}
```

### Key Configuration Sections

#### 1. Hardware Settings

```hcl
# Memory in MB
memory = 2048

# Number of CPUs
cpus = 2

# Disk size (supports K, M, G suffixes)
disk_size = "10G"

# Disk interface (virtio is fastest)
disk_interface = "virtio"  # or "ide", "scsi"

# Network device
net_device = "virtio-net"  # or "e1000", "rtl8139"
```

#### 2. Accelerator Configuration

```hcl
# Use KVM acceleration on Linux
accelerator = "kvm"

# For macOS (requires QEMU with hvf support)
# accelerator = "hvf"

# For Windows (requires WHPX)
# accelerator = "whpx"

# No acceleration (slow, but works everywhere)
# accelerator = "none"
```

#### 3. Display Configuration

```hcl
# Headless mode (no GUI)
headless = true

# VNC display (for debugging)
vnc_bind_address = "0.0.0.0"
vnc_port_min     = 5900
vnc_port_max     = 5999

# Use VNC password
vnc_use_password = false
```

#### 4. Output Configuration

```hcl
# Output directory
output_directory = "output-ubuntu"

# Image format
format = "qcow2"  # or "raw", "qed", "vdi", "vmdk", "vhdx"

# Disk compression (for qcow2)
disk_compression = true

# Skip compaction
skip_compaction = false
```

---

## ISO Boot Configuration

### Understanding Boot Commands

Boot commands automate the installation process by sending keystrokes to the VM.

### Boot Command Syntax

```hcl
boot_command = [
  "<esc><wait>",           # Press ESC, wait
  "<enter>",               # Press Enter
  "<tab>",                 # Press Tab
  "<f10>",                 # Press F10
  "<wait5>",               # Wait 5 seconds
  "text to type<enter>"    # Type text and press Enter
]
```

### Special Keys

| Key | Description |
|-----|-------------|
| `<enter>` | Enter key |
| `<esc>` | Escape key |
| `<tab>` | Tab key |
| `<f1>` - `<f12>` | Function keys |
| `<up>`, `<down>`, `<left>`, `<right>` | Arrow keys |
| `<spacebar>` | Space key |
| `<bs>` | Backspace |
| `<del>` | Delete |
| `<wait>` | Wait 1 second |
| `<wait5>` | Wait 5 seconds |
| `<wait10>` | Wait 10 seconds |

### Ubuntu 22.04 Autoinstall Boot Command

```hcl
boot_command = [
  # Wait for GRUB menu
  "<esc><wait>",
  
  # Select "Try or Install Ubuntu Server"
  # Boot with autoinstall parameters
  "linux /casper/vmlinuz ",
  "autoinstall ",
  "ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ",
  "---<enter>",
  
  # Load initrd
  "initrd /casper/initrd<enter>",
  
  # Boot
  "boot<enter>"
]
```

### Debian Preseed Boot Command

```hcl
boot_command = [
  "<esc><wait>",
  "install ",
  "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
  "debian-installer=en_US.UTF-8 ",
  "auto ",
  "locale=en_US.UTF-8 ",
  "kbd-chooser/method=us ",
  "keyboard-configuration/xkb-keymap=us ",
  "netcfg/get_hostname=debian ",
  "netcfg/get_domain=local ",
  "fb=false ",
  "debconf/frontend=noninteractive ",
  "console-setup/ask_detect=false ",
  "console-keymaps-at/keymap=us ",
  "grub-installer/bootdev=/dev/sda ",
  "<enter>"
]
```

---

## Cloud-Init Integration

### What is Cloud-Init?

**Cloud-init** is the industry standard for cloud instance initialization. It automates:

- User creation
- SSH key injection
- Package installation
- Network configuration
- Disk setup

### Cloud-Init Directory Structure

```
http/
├── meta-data          # Instance metadata
└── user-data          # Configuration
```

### meta-data Example

```yaml
instance-id: ubuntu-base
local-hostname: ubuntu-base
```

### user-data Example (Basic)

```yaml
#cloud-config
autoinstall:
  version: 1
  
  # Locale and keyboard
  locale: en_US.UTF-8
  keyboard:
    layout: us
  
  # Network (DHCP)
  network:
    network:
      version: 2
      ethernets:
        any:
          match:
            name: "e*"
          dhcp4: true
  
  # Storage (use entire disk)
  storage:
    layout:
      name: direct
  
  # User account
  identity:
    hostname: ubuntu-base
    username: ubuntu
    password: "$6$rounds=4096$saltsalt$hashed_password"
  
  # SSH
  ssh:
    install-server: true
    allow-pw: true
  
  # Packages
  packages:
    - vim
    - curl
    - wget
  
  # Late commands (run after installation)
  late-commands:
    - echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/ubuntu
```

### user-data Example (Advanced)

```yaml
#cloud-config
autoinstall:
  version: 1
  
  locale: en_US.UTF-8
  keyboard:
    layout: us
  
  network:
    network:
      version: 2
      ethernets:
        ens3:
          dhcp4: true
  
  storage:
    layout:
      name: lvm
      sizing-policy: all
  
  identity:
    hostname: ubuntu-server
    username: ubuntu
    password: "$6$rounds=4096$xyz$abc123..."
  
  ssh:
    install-server: true
    allow-pw: true
    authorized-keys:
      - "ssh-rsa AAAAB3NzaC1yc2E... user@host"
  
  packages:
    - vim
    - curl
    - wget
    - git
    - htop
    - net-tools
  
  package_update: true
  package_upgrade: true
  
  late-commands:
    # Configure sudo
    - echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/ubuntu
    - chmod 440 /target/etc/sudoers.d/ubuntu
    
    # Disable cloud-init on first boot
    - curtin in-target --target=/target -- touch /etc/cloud/cloud-init.disabled
    
    # Clean up
    - curtin in-target --target=/target -- apt-get clean
```

### Generating Password Hash

```bash
# Generate password hash for cloud-init
mkpasswd -m sha-512 -S saltsalt -R 4096

# Or using Python
python3 -c 'import crypt; print(crypt.crypt("ubuntu", crypt.mksalt(crypt.METHOD_SHA512)))'
```

---

## Provisioners Overview

### What are Provisioners?

**Provisioners** install software and configure images during the build process.

### Available Provisioners

| Provisioner | Purpose | Use Case |
|-------------|---------|----------|
| `shell` | Run shell scripts | Package installation, configuration |
| `file` | Copy files | Config files, scripts |
| `ansible` | Run Ansible playbooks | Complex configuration |
| `chef` | Run Chef recipes | Enterprise config management |
| `puppet` | Run Puppet manifests | Enterprise config management |
| `salt` | Run Salt states | Enterprise config management |

### Provisioner Execution Flow

```
Build Start
    ↓
Provisioner 1 (shell)
    ↓
Provisioner 2 (file)
    ↓
Provisioner 3 (shell)
    ↓
Provisioner 4 (cleanup)
    ↓
Build Complete
```

---

## Shell Provisioner

### Basic Shell Provisioner

```hcl
provisioner "shell" {
  inline = [
    "echo 'Starting provisioning...'",
    "sudo apt-get update",
    "sudo apt-get install -y vim curl wget"
  ]
}
```

### Shell Provisioner with Script File

```hcl
provisioner "shell" {
  script = "scripts/setup.sh"
}
```

**scripts/setup.sh**:
```bash
#!/bin/bash
set -e  # Exit on error

echo "Installing packages..."
sudo apt-get update
sudo apt-get install -y \
  vim \
  curl \
  wget \
  git \
  htop

echo "Configuring system..."
sudo timedatectl set-timezone UTC

echo "Setup complete!"
```

### Shell Provisioner with Multiple Scripts

```hcl
provisioner "shell" {
  scripts = [
    "scripts/01-update.sh",
    "scripts/02-install-packages.sh",
    "scripts/03-configure-system.sh",
    "scripts/04-cleanup.sh"
  ]
}
```

### Shell Provisioner Options

```hcl
provisioner "shell" {
  # Inline commands
  inline = ["echo 'Hello'"]
  
  # Or script file
  script = "setup.sh"
  
  # Or multiple scripts
  scripts = ["script1.sh", "script2.sh"]
  
  # Environment variables
  environment_vars = [
    "DEBIAN_FRONTEND=noninteractive",
    "APP_VERSION=1.0.0"
  ]
  
  # Execute command (how to run the script)
  execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
  
  # Inline shebang
  inline_shebang = "/bin/bash -e"
  
  # Expect disconnect (for reboots)
  expect_disconnect = false
  
  # Pause before/after
  pause_before = "10s"
  pause_after  = "5s"
  
  # Timeout
  timeout = "30m"
  
  # Valid exit codes
  valid_exit_codes = [0]
}
```

### Common Shell Provisioning Tasks

#### 1. System Update

```hcl
provisioner "shell" {
  inline = [
    "sudo apt-get update",
    "sudo apt-get upgrade -y"
  ]
}
```

#### 2. Package Installation

```hcl
provisioner "shell" {
  environment_vars = [
    "DEBIAN_FRONTEND=noninteractive"
  ]
  inline = [
    "sudo apt-get install -y nginx",
    "sudo systemctl enable nginx"
  ]
}
```

#### 3. User Creation

```hcl
provisioner "shell" {
  inline = [
    "sudo useradd -m -s /bin/bash appuser",
    "echo 'appuser:password' | sudo chpasswd",
    "sudo usermod -aG sudo appuser"
  ]
}
```

#### 4. Service Configuration

```hcl
provisioner "shell" {
  inline = [
    "sudo systemctl enable nginx",
    "sudo systemctl start nginx",
    "sudo systemctl status nginx"
  ]
}
```

---

## File Provisioner

### Basic File Provisioner

```hcl
provisioner "file" {
  source      = "files/config.conf"
  destination = "/tmp/config.conf"
}
```

### File Provisioner Options

```hcl
provisioner "file" {
  # Single file
  source      = "files/app.conf"
  destination = "/tmp/app.conf"
  
  # Or directory
  source      = "files/"
  destination = "/tmp/files/"
  
  # Or content directly
  content     = "Hello World"
  destination = "/tmp/hello.txt"
  
  # Direction (upload or download)
  direction = "upload"  # or "download"
  
  # Generated content
  generated = false
}
```

### Copying Multiple Files

```hcl
# Copy individual files
provisioner "file" {
  source      = "configs/nginx.conf"
  destination = "/tmp/nginx.conf"
}

provisioner "file" {
  source      = "configs/app.conf"
  destination = "/tmp/app.conf"
}

# Or copy entire directory
provisioner "file" {
  source      = "configs/"
  destination = "/tmp/configs/"
}
```

### File Provisioner with Shell

```hcl
# Copy file
provisioner "file" {
  source      = "configs/nginx.conf"
  destination = "/tmp/nginx.conf"
}

# Move to final location
provisioner "shell" {
  inline = [
    "sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf",
    "sudo chown root:root /etc/nginx/nginx.conf",
    "sudo chmod 644 /etc/nginx/nginx.conf"
  ]
}
```

### Generating Content

```hcl
provisioner "file" {
  content = <<-EOF
    #!/bin/bash
    echo "Generated script"
    date
  EOF
  destination = "/tmp/generated.sh"
}

provisioner "shell" {
  inline = [
    "chmod +x /tmp/generated.sh",
    "/tmp/generated.sh"
  ]
}
```

---

## Provisioner Execution Order

### Sequential Execution

Provisioners run in the order they're defined:

```hcl
build {
  sources = ["source.qemu.ubuntu"]
  
  # 1. Update system
  provisioner "shell" {
    inline = ["sudo apt-get update"]
  }
  
  # 2. Install packages
  provisioner "shell" {
    inline = ["sudo apt-get install -y nginx"]
  }
  
  # 3. Copy configuration
  provisioner "file" {
    source      = "nginx.conf"
    destination = "/tmp/nginx.conf"
  }
  
  # 4. Apply configuration
  provisioner "shell" {
    inline = [
      "sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf",
      "sudo systemctl restart nginx"
    ]
  }
}
```

### Conditional Provisioning

```hcl
provisioner "shell" {
  # Only run on Linux
  only = ["qemu.ubuntu"]
  
  inline = ["sudo apt-get update"]
}

provisioner "shell" {
  # Skip for specific builds
  except = ["qemu.minimal"]
  
  inline = ["sudo apt-get install -y nginx"]
}
```

### Pausing Between Provisioners

```hcl
provisioner "shell" {
  inline = ["sudo apt-get install -y nginx"]
  
  # Wait 10 seconds after this provisioner
  pause_after = "10s"
}

provisioner "shell" {
  # Wait 5 seconds before this provisioner
  pause_before = "5s"
  
  inline = ["sudo systemctl start nginx"]
}
```

---

## Error Handling

### Handling Provisioner Failures

```hcl
provisioner "shell" {
  inline = [
    "sudo apt-get update",
    "sudo apt-get install -y nginx"
  ]
  
  # Valid exit codes (default: [0])
  valid_exit_codes = [0]
  
  # Timeout
  timeout = "30m"
}
```

### Continuing on Error

```hcl
provisioner "shell" {
  inline = [
    "command_that_might_fail || true",
    "sudo apt-get install -y nginx"
  ]
}
```

### Error Handling in Scripts

```bash
#!/bin/bash
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Function for error handling
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Use error handling
sudo apt-get update || error_exit "Failed to update packages"
sudo apt-get install -y nginx || error_exit "Failed to install nginx"

echo "Success!"
```

### Retry Logic

```bash
#!/bin/bash

# Retry function
retry() {
  local max_attempts=3
  local timeout=5
  local attempt=1
  local exitCode=0

  while [ $attempt -le $max_attempts ]; do
    "$@"
    exitCode=$?

    if [ $exitCode -eq 0 ]; then
      break
    fi

    echo "Attempt $attempt failed. Retrying in $timeout seconds..."
    sleep $timeout
    attempt=$((attempt + 1))
  done

  return $exitCode
}

# Use retry
retry sudo apt-get update
retry sudo apt-get install -y nginx
```

---

## Advanced Provisioning Patterns

### Pattern 1: Multi-Stage Provisioning

```hcl
build {
  sources = ["source.qemu.ubuntu"]
  
  # Stage 1: System preparation
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y"
    ]
  }
  
  # Stage 2: Package installation
  provisioner "shell" {
    scripts = [
      "scripts/install-base.sh",
      "scripts/install-web.sh",
      "scripts/install-monitoring.sh"
    ]
  }
  
  # Stage 3: Configuration
  provisioner "file" {
    source      = "configs/"
    destination = "/tmp/configs/"
  }
  
  provisioner "shell" {
    script = "scripts/apply-configs.sh"
  }
  
  # Stage 4: Cleanup
  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }
}
```

### Pattern 2: Environment-Specific Provisioning

```hcl
variable "environment" {
  type    = string
  default = "dev"
}

build {
  sources = ["source.qemu.ubuntu"]
  
  # Common provisioning
  provisioner "shell" {
    inline = ["sudo apt-get update"]
  }
  
  # Development-specific
  provisioner "shell" {
    only = ["qemu.ubuntu"]
    inline = [
      "if [ '${var.environment}' = 'dev' ]; then",
      "  sudo apt-get install -y build-essential",
      "fi"
    ]
  }
  
  # Production-specific
  provisioner "shell" {
    inline = [
      "if [ '${var.environment}' = 'prod' ]; then",
      "  sudo apt-get install -y monitoring-agent",
      "fi"
    ]
  }
}
```

### Pattern 3: Idempotent Provisioning

```bash
#!/bin/bash
# idempotent-setup.sh

# Check if already installed
if ! command -v nginx &> /dev/null; then
  echo "Installing nginx..."
  sudo apt-get update
  sudo apt-get install -y nginx
else
  echo "nginx already installed"
fi

# Check if service is enabled
if ! systemctl is-enabled nginx &> /dev/null; then
  echo "Enabling nginx..."
  sudo systemctl enable nginx
else
  echo "nginx already enabled"
fi
```

### Pattern 4: Cleanup Provisioning

```hcl
# Final cleanup provisioner
provisioner "shell" {
  inline = [
    # Remove temporary files
    "sudo rm -rf /tmp/*",
    
    # Clear package cache
    "sudo apt-get autoremove -y",
    "sudo apt-get clean",
    
    # Clear logs
    "sudo find /var/log -type f -exec truncate -s 0 {} \\;",
    
    # Clear bash history
    "cat /dev/null > ~/.bash_history",
    "history -c",
    
    # Zero out free space (for compression)
    "sudo dd if=/dev/zero of=/EMPTY bs=1M || true",
    "sudo rm -f /EMPTY"
  ]
}
```

---

## Best Practices

### 1. Use Scripts for Complex Logic

```hcl
# ❌ Bad: Complex inline commands
provisioner "shell" {
  inline = [
    "if [ ! -f /etc/nginx/nginx.conf ]; then sudo apt-get install -y nginx; fi",
    "sudo sed -i 's/worker_processes auto/worker_processes 4/' /etc/nginx/nginx.conf"
  ]
}

# ✅ Good: External script
provisioner "shell" {
  script = "scripts/setup-nginx.sh"
}
```

### 2. Make Scripts Idempotent

```bash
# ✅ Good: Idempotent script
#!/bin/bash

# Check before installing
if ! command -v nginx &> /dev/null; then
  sudo apt-get update
  sudo apt-get install -y nginx
fi

# Check before configuring
if ! grep -q "worker_processes 4" /etc/nginx/nginx.conf; then
  sudo sed -i 's/worker_processes auto/worker_processes 4/' /etc/nginx/nginx.conf
fi
```

### 3. Use Environment Variables

```hcl
provisioner "shell" {
  environment_vars = [
    "DEBIAN_FRONTEND=noninteractive",
    "APP_VERSION=1.0.0",
    "INSTALL_DIR=/opt/app"
  ]
  script = "scripts/install-app.sh"
}
```

### 4. Handle Errors Properly

```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined var, pipe failure

# Log function
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Error function
error() {
  log "ERROR: $*" >&2
  exit 1
}

# Use functions
log "Starting installation..."
sudo apt-get update || error "Failed to update packages"
log "Installation complete"
```

### 5. Clean Up After Provisioning

```hcl
# Always include cleanup
provisioner "shell" {
  inline = [
    "sudo apt-get autoremove -y",
    "sudo apt-get clean",
    "sudo rm -rf /tmp/*",
    "sudo rm -rf /var/tmp/*"
  ]
}
```

### 6. Test Scripts Locally First

```bash
# Test script before using in Packer
bash -n script.sh  # Check syntax
shellcheck script.sh  # Lint script
bash script.sh  # Run locally
```

---

## Hands-On Labs

### Lab 1: QEMU Builder Configuration (20 minutes)

**Objective**: Create a fully configured QEMU builder template

**Tasks**:
1. Create a complete QEMU builder configuration
2. Configure hardware settings (memory, CPU, disk)
3. Set up ISO boot with cloud-init
4. Build the image
5. Verify the output

**Starter Template** (`complete-builder.pkr.hcl`):
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

variable "vm_name" {
  type    = string
  default = "ubuntu-configured"
}

variable "memory" {
  type    = number
  default = 2048
}

variable "cpus" {
  type    = number
  default = 2
}

source "qemu" "ubuntu" {
  vm_name      = var.vm_name
  memory       = var.memory
  cpus         = var.cpus
  disk_size    = "10G"
  format       = "qcow2"
  accelerator  = "kvm"
  
  iso_url      = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
  iso_checksum = "sha256:a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"
  
  output_directory = "output-${var.vm_name}"
  
  headless = true
  
  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "linux /casper/vmlinuz autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<enter>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]
  
  http_directory = "http"
  
  ssh_username = "ubuntu"
  ssh_password = "ubuntu"
  ssh_timeout  = "20m"
  
  shutdown_command = "echo 'ubuntu' | sudo -S shutdown -P now"
}

build {
  sources = ["source.qemu.ubuntu"]
  
  provisioner "shell" {
    inline = [
      "echo 'Build successful!'",
      "uname -a"
    ]
  }
}
```

**Your Task**:
1. Create the template
2. Create `http/user-data` and `http/meta-data` files
3. Build the image with different configurations
4. Test with various memory/CPU settings

**Expected Result**:
```bash
$ packer build -var 'memory=4096' -var 'cpus=4' complete-builder.pkr.hcl
Build 'qemu.ubuntu' finished after 15 minutes.
```

---

### Lab 2: Shell Provisioning (25 minutes)

**Objective**: Use shell provisioners to customize an image

**Tasks**:
1. Create provisioners for package installation
2. Add system configuration
3. Create cleanup provisioner
4. Build and test the image

**Template** (`shell-provisioning.pkr.hcl`):
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
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "sudo apt-get install -y vim curl wget git htop",
      "sudo apt-get install -y nginx"
    ]
  }
  
  # Configure system
  provisioner "shell" {
    inline = [
      "sudo systemctl enable nginx",
      "sudo timedatectl set-timezone UTC",
      "echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ubuntu"
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
1. Add more packages to install
2. Create a custom script file for configuration
3. Add user creation provisioner
4. Build and verify customizations

**Expected Result**:
```bash
$ packer build shell-provisioning.pkr.hcl
# Image built with all customizations

$ qemu-system-x86_64 -m 2048 -drive file=output-ubuntu/ubuntu-configured,format=qcow2
# Boot and verify: nginx installed, timezone set, packages present
```

---

### Lab 3: File Provisioning and Multi-Stage Build (30 minutes)

**Objective**: Combine file and shell provisioners for complex configuration

**Tasks**:
1. Create configuration files
2. Use file provisioner to copy them
3. Use shell provisioner to apply them
4. Build multi-stage provisioning workflow

**Directory Structure**:
```
lab3/
├── build.pkr.hcl
├── http/
│   ├── user-data
│   └── meta-data
├── configs/
│   ├── nginx.conf
│   ├── motd
│   └── bashrc
└── scripts/
    ├── install.sh
    ├── configure.sh
    └── cleanup.sh
```

**Template** (`build.pkr.hcl`):
```hcl
build {
  sources = ["source.qemu.ubuntu"]
  
  # Stage 1: Installation
  provisioner "shell" {
    script = "scripts/install.sh"
  }
  
  # Stage 2: Copy configurations
  provisioner "file" {
    source      = "configs/"
    destination = "/tmp/configs/"
  }
  
  # Stage 3: Apply configurations
  provisioner "shell" {
    script = "scripts/configure.sh"
  }
  
  # Stage 4: Cleanup
  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }
}
```

**Your Task**:
1. Create all configuration files
2. Create all script files
3. Build the image
4. Verify all configurations are applied

**Expected Result**:
```bash
$ packer build build.pkr.hcl
# Multi-stage build completes successfully

$ qemu-system-x86_64 -m 2048 -drive file=output-ubuntu/ubuntu-configured,format=qcow2
# Boot and verify: custom MOTD, nginx configured, all settings applied
```

---

## Checkpoint Quiz

### Question 1: QEMU Accelerator
**Which accelerator should you use for best performance on Linux?**

A) none  
B) hvf  
C) kvm  
D) whpx

<details>
<summary>Show Answer</summary>

**Answer: C) kvm**

**Explanation**: KVM (Kernel-based Virtual Machine) provides the best performance on Linux systems with hardware virtualization support. Other accelerators:
- `hvf`: macOS (Hypervisor Framework)
- `whpx`: Windows (Windows Hypervisor Platform)
- `none`: No acceleration (slow, but works everywhere)

</details>

---

### Question 2: Boot Commands
**What does `<wait5>` do in a boot command?**

A) Wait for 5 keystrokes  
B) Wait 5 seconds  
C) Press F5  
D) Repeat previous command 5 times

<details>
<summary>Show Answer</summary>

**Answer: B) Wait 5 seconds**

**Explanation**: `<wait5>` pauses for 5 seconds during boot command execution. This is useful when the system needs time to process previous commands. Other wait options include `<wait>` (1 second) and `<wait10>` (10 seconds).

</details>

---

### Question 3: Provisioner Order
**In what order do provisioners execute?**

A) Alphabetically by name  
B) Random order  
C) In the order they're defined  
D) Parallel execution

<details>
<summary>Show Answer</summary>

**Answer: C) In the order they're defined**

**Explanation**: Provisioners execute sequentially in the order they appear in the build block. This allows you to control the provisioning workflow, such as installing packages before copying configuration files.

</details>

---

### Question 4: File Provisioner
**What is the default direction for the file provisioner?**

A) download  
B) upload  
C) bidirectional  
D) none

<details>
<summary>Show Answer</summary>

**Answer: B) upload**

**Explanation**: The file provisioner defaults to uploading files from the local machine to the VM being built. You can set `direction = "download"` to copy files from the VM to your local machine (useful for extracting artifacts).

</details>

---

### Question 5: Shell Provisioner Error Handling
**What does `set -e` do in a shell script?**

A) Enable echo  
B) Exit on error  
C) Enable encryption  
D) Export variables

<details>
<summary>Show Answer</summary>

**Answer: B) Exit on error**

**Explanation**: `set -e` causes the script to exit immediately if any command returns a non-zero exit code. This is important for error handling in provisioning scripts. Other useful options:
- `set -u`: Exit on undefined variable
- `set -o pipefail`: Exit on pipe failure
- `set -x`: Print commands before execution (debugging)

</details>

---

### Question 6: Cloud-Init
**What is the purpose of cloud-init in Packer builds?**

A) Initialize cloud storage  
B) Automate OS installation and initial configuration  
C) Connect to cloud providers  
D) Initialize networking only

<details>
<summary>Show Answer</summary>

**Answer: B) Automate OS installation and initial configuration**

**Explanation**: Cloud-init automates the OS installation process, including:
- User creation
- SSH key injection
- Package installation
- Network configuration
- Disk partitioning

This eliminates the need for manual installation steps and makes the build process fully automated.

</details>

---

## Additional Resources

### Official Documentation
- [QEMU Builder](https://www.packer.io/docs/builders/qemu)
- [Shell Provisioner](https://www.packer.io/docs/provisioners/shell)
- [File Provisioner](https://www.packer.io/docs/provisioners/file)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)

### Tools and Utilities
- [QEMU Documentation](https://www.qemu.org/documentation/)
- [Cloud-Init Examples](https://cloudinit.readthedocs.io/en/latest/topics/examples.html)
- [ShellCheck](https://www.shellcheck.net/) - Shell script linter

### Community Resources
- [Packer Examples](https://github.com/hashicorp/packer/tree/main/examples)
- [Bento Boxes](https://github.com/chef/bento) - Example Packer templates

### Next Steps
- **PKR-103**: Ansible Configuration Management (advanced provisioning)
- **PKR-104**: Image Versioning & HCP Packer (image management)

---

## Summary

In this course, you learned:

✅ **QEMU Builder**: Complete configuration options  
✅ **ISO Boot**: Boot commands and automation  
✅ **Cloud-Init**: Automated OS installation  
✅ **Shell Provisioner**: Package installation and configuration  
✅ **File Provisioner**: Copying files and configurations  
✅ **Execution Order**: Sequential provisioning workflow  
✅ **Error Handling**: Robust provisioning scripts  
✅ **Advanced Patterns**: Multi-stage, environment-specific, idempotent  
✅ **Best Practices**: Scripts, idempotency, cleanup, testing

### Key Takeaways

1. **QEMU Builder**: Powerful, flexible, production-ready
2. **Cloud-Init**: Essential for automated installation
3. **Provisioners**: Chain them for complex workflows
4. **Idempotency**: Scripts should be safe to run multiple times
5. **Error Handling**: Always handle errors properly
6. **Cleanup**: Always clean up temporary files and caches

### What's Next?

Continue to **PKR-103: Ansible Configuration Management** to learn:
- Ansible provisioner configuration
- Playbook integration
- Role-based provisioning
- Complex configuration management

---

**Course**: PKR-100 Packer Fundamentals  
**Module**: PKR-102 - QEMU Builder & Provisioners  
**Duration**: 1 hour  
**Last Updated**: 2026-02-26
---

## 📚 Supplemental Content

| Topic | Description | Directory |
|-------|-------------|-----------|
| [Post-Processors](post-processors/README.md) | `shell-local` and `manifest` post-processors | `post-processors/` |

### What You've Learned (Updated)

In addition to the core content above, the supplemental section covers:

- ✅ **Post-Processors**: Run commands on the build machine after image creation
- ✅ **`shell-local`**: Compress, move, or notify after a build
- ✅ **`manifest`**: Record build metadata to JSON for CI/CD pipelines
- ✅ **Chaining**: Combine multiple post-processors in sequence