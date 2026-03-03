# Base Image Preparation Guide

**Purpose**: Prepare minimal base images for Terraform and Packer training with Libvirt  
**Target Audience**: Students starting the core training program  
**Prerequisites**: Libvirt installed and configured (see [libvirt-setup.md](libvirt-setup.md))

---

## Table of Contents

1. [Overview](#overview)
2. [Ubuntu Cloud Images](#ubuntu-cloud-images)
3. [Alpine Linux Images](#alpine-linux-images)
4. [Importing and Resizing Images](#importing-and-resizing-images)
5. [Cloud-Init Configuration](#cloud-init-configuration)
6. [Image Customization](#image-customization)
7. [Image Verification](#image-verification)
8. [Storage Optimization](#storage-optimization)
9. [Troubleshooting](#troubleshooting)

---

## Overview

### Why Base Images?

Base images are pre-configured operating system templates that serve as starting points for creating virtual machines. Using base images:

- **Saves Time**: No need to install OS from scratch
- **Ensures Consistency**: All VMs start from the same baseline
- **Reduces Storage**: Thin provisioning and copy-on-write
- **Speeds Learning**: Focus on IaC concepts, not OS installation

### Image Options

This training supports two base image options:

| Image | Size | Use Case | Recommended For |
|-------|------|----------|-----------------|
| **Ubuntu 22.04 Cloud** | ~700 MB | General purpose, well-documented | Beginners, most courses |
| **Alpine Linux** | ~50 MB | Minimal, fast boot, low resource | Advanced users, resource-constrained systems |

### Storage Requirements

- **Per Base Image**: 1-2 GB (compressed)
- **Per VM Instance**: 2-10 GB (depends on usage)
- **Recommended Free Space**: 50 GB minimum for training

---

## Ubuntu Cloud Images

### 0.3.1: Download Ubuntu Cloud Images

Ubuntu provides official cloud images optimized for virtualization.

#### Download Latest Ubuntu 22.04 LTS

```bash
# Create images directory
mkdir -p ~/libvirt-images
cd ~/libvirt-images

# Download Ubuntu 22.04 LTS cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Verify download (optional but recommended)
wget https://cloud-images.ubuntu.com/jammy/current/SHA256SUMS
sha256sum -c SHA256SUMS 2>&1 | grep jammy-server-cloudimg-amd64.img
```

**PowerShell (Windows/WSL2)**:
```powershell
# Create images directory
New-Item -ItemType Directory -Force -Path "$HOME\libvirt-images"
cd "$HOME\libvirt-images"

# Download using Invoke-WebRequest
Invoke-WebRequest -Uri "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img" -OutFile "jammy-server-cloudimg-amd64.img"
```

#### Image Details

- **OS**: Ubuntu 22.04 LTS (Jammy Jellyfish)
- **Format**: QCOW2 (compressed)
- **Size**: ~700 MB compressed, ~2.2 GB uncompressed
- **Architecture**: x86_64 (amd64)
- **Default User**: `ubuntu` (password authentication disabled)
- **Cloud-Init**: Pre-installed and enabled

#### Alternative Versions

```bash
# Ubuntu 20.04 LTS (Focal)
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

# Ubuntu 24.04 LTS (Noble) - when available
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
```

#### Verify Image Integrity

```bash
# Check image format
qemu-img info jammy-server-cloudimg-amd64.img

# Expected output:
# image: jammy-server-cloudimg-amd64.img
# file format: qcow2
# virtual size: 2.2 GiB
# disk size: 700 MiB
```

---

## Alpine Linux Images

### 0.3.2: Alpine Linux Minimal Image

Alpine Linux is an ultra-lightweight distribution perfect for learning and resource-constrained environments.

#### Download Alpine Linux

```bash
# Create images directory (if not exists)
mkdir -p ~/libvirt-images
cd ~/libvirt-images

# Download Alpine Linux virtual image (latest stable)
wget https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-virt-3.19.0-x86_64.iso

# For cloud-init enabled image (recommended)
wget https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/cloud/alpine-cloud-3.19.0-x86_64.qcow2
```

**PowerShell**:
```powershell
cd "$HOME\libvirt-images"

# Download cloud-init enabled image
Invoke-WebRequest -Uri "https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/cloud/alpine-cloud-3.19.0-x86_64.qcow2" -OutFile "alpine-cloud-3.19.0-x86_64.qcow2"
```

#### Image Details

- **OS**: Alpine Linux 3.19
- **Format**: QCOW2 (cloud image) or ISO (virtual)
- **Size**: ~50 MB (cloud image), ~200 MB (ISO)
- **Architecture**: x86_64
- **Package Manager**: apk
- **Init System**: OpenRC
- **Default User**: `alpine` (cloud image)

#### Why Alpine?

**Advantages**:
- ✅ Extremely small footprint (~50 MB)
- ✅ Fast boot times (< 5 seconds)
- ✅ Low memory usage (~20 MB idle)
- ✅ Security-focused (musl libc, no systemd)
- ✅ Perfect for learning IaC concepts

**Considerations**:
- ⚠️ Uses musl libc (not glibc) - some binaries may not work
- ⚠️ Smaller package repository than Ubuntu
- ⚠️ Less familiar for beginners

#### Verify Alpine Image

```bash
qemu-img info alpine-cloud-3.19.0-x86_64.qcow2

# Expected output:
# image: alpine-cloud-3.19.0-x86_64.qcow2
# file format: qcow2
# virtual size: 1 GiB
# disk size: 50 MiB
```

---

## Importing and Resizing Images

### 0.3.3: Import and Resize Base Images

Cloud images are typically small and need to be resized for actual use.

#### Copy Image to Libvirt Pool

```bash
# Default libvirt images location
POOL_DIR="/var/lib/libvirt/images"

# Copy Ubuntu image
sudo cp ~/libvirt-images/jammy-server-cloudimg-amd64.img \
  $POOL_DIR/ubuntu-22.04-base.qcow2

# Copy Alpine image
sudo cp ~/libvirt-images/alpine-cloud-3.19.0-x86_64.qcow2 \
  $POOL_DIR/alpine-3.19-base.qcow2

# Set proper permissions
sudo chown libvirt-qemu:kvm $POOL_DIR/*.qcow2
sudo chmod 644 $POOL_DIR/*.qcow2
```

**PowerShell (WSL2)**:
```powershell
# WSL2 libvirt location
$POOL_DIR = "/var/lib/libvirt/images"

# Copy images (run in WSL2 terminal)
wsl sudo cp ~/libvirt-images/jammy-server-cloudimg-amd64.img $POOL_DIR/ubuntu-22.04-base.qcow2
wsl sudo chown libvirt-qemu:kvm $POOL_DIR/ubuntu-22.04-base.qcow2
```

#### Resize Images

Cloud images are small by default. Resize them for your needs:

```bash
# Resize Ubuntu image to 20 GB
sudo qemu-img resize $POOL_DIR/ubuntu-22.04-base.qcow2 20G

# Resize Alpine image to 10 GB
sudo qemu-img resize $POOL_DIR/alpine-3.19-base.qcow2 10G

# Verify new size
qemu-img info $POOL_DIR/ubuntu-22.04-base.qcow2
```

**Output**:
```
image: ubuntu-22.04-base.qcow2
file format: qcow2
virtual size: 20 GiB    # <-- New size
disk size: 700 MiB      # <-- Actual disk usage (thin provisioned)
```

#### Create Backing Images (Copy-on-Write)

Instead of copying the base image for each VM, use backing images:

```bash
# Create a new VM image backed by the base image
qemu-img create -f qcow2 \
  -F qcow2 \
  -b $POOL_DIR/ubuntu-22.04-base.qcow2 \
  $POOL_DIR/vm-instance-01.qcow2 \
  20G

# This creates a thin image that only stores differences
# Base image remains read-only and shared
```

**Benefits**:
- ✅ Saves disk space (only stores differences)
- ✅ Fast VM creation (no copying)
- ✅ Base image remains pristine
- ✅ Multiple VMs can share one base image

#### Resize Filesystem (Inside VM)

After resizing the image, you need to resize the filesystem inside the VM:

```bash
# For Ubuntu (after first boot)
sudo growpart /dev/vda 1
sudo resize2fs /dev/vda1

# For Alpine
sudo growpart /dev/vda 3
sudo resize2fs /dev/vda3
```

Or use cloud-init to do this automatically (see next section).

---

## Cloud-Init Configuration

### 0.3.4: Cloud-Init Configuration Examples

Cloud-init automates VM initialization (users, SSH keys, packages, etc.).

#### What is Cloud-Init?

Cloud-init is a standard for VM initialization across cloud providers. It:
- Creates users and sets passwords/SSH keys
- Configures networking
- Installs packages
- Runs custom scripts
- Resizes filesystems automatically

#### Basic Cloud-Init Configuration

Create a minimal cloud-init configuration:

```yaml
# cloud-init-basic.yaml
#cloud-config

# Set hostname
hostname: terraform-vm-01

# Create user
users:
  - name: student
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2E... your-public-key

# Set password (optional, for console access)
chpasswd:
  list: |
    student:training123
  expire: false

# Install packages
packages:
  - vim
  - curl
  - git
  - htop

# Resize root filesystem
growpart:
  mode: auto
  devices: ['/']

# Run commands on first boot
runcmd:
  - echo "VM initialized successfully" > /etc/motd
  - systemctl enable ssh
```

#### Advanced Cloud-Init with Terraform

```yaml
# cloud-init-terraform.yaml
#cloud-config

hostname: ${hostname}

users:
  - name: ${username}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_public_key}

packages:
  - vim
  - curl
  - git
  - python3
  - python3-pip

write_files:
  - path: /etc/environment
    content: |
      TRAINING_ENV=terraform-course
      COURSE_ID=${course_id}
    permissions: '0644'

runcmd:
  - echo "Welcome to Terraform Training!" > /etc/motd
  - pip3 install ansible
  - systemctl restart ssh

final_message: "VM ${hostname} is ready after $UPTIME seconds"
```

#### Using Cloud-Init with Terraform

```hcl
# Terraform example using cloud-init
data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-init.yaml")
  
  vars = {
    hostname       = "tf-vm-${count.index + 1}"
    username       = "student"
    ssh_public_key = file("~/.ssh/id_rsa.pub")
    course_id      = "TF-101"
  }
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "cloudinit-${count.index}.iso"
  user_data = data.template_file.cloud_init.rendered
}

resource "libvirt_domain" "vm" {
  name   = "terraform-vm-${count.index + 1}"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.commoninit.id
  
  # ... rest of configuration
}
```

#### Cloud-Init for Alpine Linux

Alpine requires slightly different configuration:

```yaml
#cloud-config

hostname: alpine-vm-01

users:
  - name: student
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/ash  # Alpine uses ash, not bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2E... your-key

packages:
  - vim
  - curl
  - git

# Alpine-specific commands
runcmd:
  - rc-update add sshd default
  - rc-service sshd start
  - echo "Alpine VM ready" > /etc/motd
```

#### Testing Cloud-Init

```bash
# Check cloud-init status (inside VM)
cloud-init status

# View cloud-init logs
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log

# Re-run cloud-init (for testing)
sudo cloud-init clean
sudo cloud-init init
```

---

## Image Customization

### 0.3.5: Image Customization Process

Customize base images for specific training needs.

#### Method 1: Using virt-customize (Recommended)

`virt-customize` modifies images without booting them:

```bash
# Install virt-customize (part of libguestfs-tools)
sudo apt install libguestfs-tools  # Ubuntu/Debian
sudo yum install libguestfs-tools  # RHEL/CentOS

# Customize Ubuntu image
sudo virt-customize -a ubuntu-22.04-base.qcow2 \
  --root-password password:training123 \
  --install vim,curl,git,htop \
  --run-command 'systemctl enable ssh' \
  --run-command 'echo "Welcome to Terraform Training" > /etc/motd' \
  --timezone Europe/Stockholm \
  --hostname terraform-base

# Customize Alpine image
sudo virt-customize -a alpine-3.19-base.qcow2 \
  --root-password password:training123 \
  --install vim,curl,git \
  --run-command 'rc-update add sshd default' \
  --timezone Europe/Stockholm
```

#### Method 2: Manual Customization

Boot the image, make changes, then save:

```bash
# 1. Create a temporary VM
virt-install \
  --name temp-customize \
  --memory 2048 \
  --vcpus 2 \
  --disk path=/var/lib/libvirt/images/ubuntu-22.04-base.qcow2 \
  --import \
  --os-variant ubuntu22.04 \
  --graphics none \
  --console pty,target_type=serial

# 2. Make your changes inside the VM
# - Install packages
# - Configure services
# - Create users
# - etc.

# 3. Shutdown the VM
sudo shutdown -h now

# 4. Clean up
virsh undefine temp-customize

# 5. The image is now customized
```

#### Method 3: Using Packer (Advanced)

Create customized images with Packer (covered in PKR-100 series):

```hcl
# ubuntu-custom.pkr.hcl
source "qemu" "ubuntu" {
  iso_url      = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  iso_checksum = "sha256:..."
  disk_image   = true
  format       = "qcow2"
  
  ssh_username = "ubuntu"
  ssh_password = "ubuntu"
  
  shutdown_command = "sudo shutdown -P now"
}

build {
  sources = ["source.qemu.ubuntu"]
  
  provisioner "shell" {
    inline = [
      "sudo apt update",
      "sudo apt install -y vim curl git htop",
      "echo 'Welcome to Terraform Training' | sudo tee /etc/motd"
    ]
  }
}
```

#### Common Customizations

**Install Development Tools**:
```bash
# Ubuntu
sudo apt update
sudo apt install -y build-essential python3-pip ansible

# Alpine
sudo apk update
sudo apk add build-base python3 py3-pip ansible
```

**Configure SSH**:
```bash
# Enable password authentication (for learning only!)
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

**Set Timezone**:
```bash
sudo timedatectl set-timezone Europe/Stockholm
```

**Add Training User**:
```bash
sudo useradd -m -s /bin/bash -G sudo student
echo "student:training123" | sudo chpasswd
```

---

## Image Verification

### 0.3.6: Image Verification Checklist

Verify images are ready for training use.

#### Pre-Flight Checklist

Use this checklist before using images in training:

```markdown
## Base Image Verification Checklist

### Image File Checks
- [ ] Image file exists in libvirt pool
- [ ] Image format is QCOW2
- [ ] Image size is appropriate (10-20 GB virtual size)
- [ ] Image permissions are correct (644, owned by libvirt-qemu)
- [ ] Image is not corrupted (qemu-img check passes)

### Boot and Access Checks
- [ ] VM boots successfully from image
- [ ] Boot time is reasonable (< 30 seconds)
- [ ] Console access works
- [ ] SSH access works (if configured)
- [ ] Network connectivity works (can ping external hosts)

### User and Authentication Checks
- [ ] Default user exists and can login
- [ ] SSH key authentication works (if configured)
- [ ] Password authentication works (if enabled)
- [ ] User has sudo privileges
- [ ] No password required for sudo (NOPASSWD configured)

### System Configuration Checks
- [ ] Hostname is set correctly
- [ ] Timezone is configured
- [ ] DNS resolution works
- [ ] Package manager works (apt/apk)
- [ ] Required packages are installed

### Cloud-Init Checks (if applicable)
- [ ] Cloud-init is installed
- [ ] Cloud-init runs on first boot
- [ ] Cloud-init configuration is applied
- [ ] Filesystem is resized automatically
- [ ] No cloud-init errors in logs

### Performance Checks
- [ ] Memory usage is reasonable (< 500 MB idle)
- [ ] CPU usage is low when idle
- [ ] Disk I/O is responsive
- [ ] No unnecessary services running
```

#### Automated Verification Script

```bash
#!/bin/bash
# verify-image.sh - Verify base image readiness

IMAGE_PATH="$1"

if [ -z "$IMAGE_PATH" ]; then
  echo "Usage: $0 <path-to-image>"
  exit 1
fi

echo "=== Image Verification Report ==="
echo "Image: $IMAGE_PATH"
echo ""

# Check 1: File exists
echo "✓ Checking file existence..."
if [ ! -f "$IMAGE_PATH" ]; then
  echo "✗ FAIL: Image file not found"
  exit 1
fi
echo "  ✓ PASS: File exists"

# Check 2: Image format
echo "✓ Checking image format..."
FORMAT=$(qemu-img info "$IMAGE_PATH" | grep "file format" | awk '{print $3}')
if [ "$FORMAT" != "qcow2" ]; then
  echo "✗ FAIL: Expected qcow2, got $FORMAT"
  exit 1
fi
echo "  ✓ PASS: Format is qcow2"

# Check 3: Image integrity
echo "✓ Checking image integrity..."
if ! qemu-img check "$IMAGE_PATH" > /dev/null 2>&1; then
  echo "✗ FAIL: Image is corrupted"
  exit 1
fi
echo "  ✓ PASS: Image integrity OK"

# Check 4: Image size
echo "✓ Checking image size..."
VIRTUAL_SIZE=$(qemu-img info "$IMAGE_PATH" | grep "virtual size" | awk '{print $3}')
echo "  ✓ Virtual size: $VIRTUAL_SIZE"

# Check 5: Disk usage
DISK_SIZE=$(qemu-img info "$IMAGE_PATH" | grep "disk size" | awk '{print $3}')
echo "  ✓ Disk usage: $DISK_SIZE"

echo ""
echo "=== Verification Complete ==="
echo "Image is ready for use!"
```

**Usage**:
```bash
chmod +x verify-image.sh
./verify-image.sh /var/lib/libvirt/images/ubuntu-22.04-base.qcow2
```

#### Manual Verification Steps

**1. Check Image Info**:
```bash
qemu-img info /var/lib/libvirt/images/ubuntu-22.04-base.qcow2
```

**2. Check Image Integrity**:
```bash
qemu-img check /var/lib/libvirt/images/ubuntu-22.04-base.qcow2
```

**3. Test Boot**:
```bash
# Create test VM
virt-install \
  --name test-vm \
  --memory 2048 \
  --vcpus 2 \
  --disk path=/var/lib/libvirt/images/ubuntu-22.04-base.qcow2 \
  --import \
  --os-variant ubuntu22.04 \
  --graphics none \
  --console pty,target_type=serial

# After testing, clean up
virsh destroy test-vm
virsh undefine test-vm
```

**4. Verify Cloud-Init** (inside VM):
```bash
# Check cloud-init status
cloud-init status

# Should show: status: done

# Check for errors
sudo journalctl -u cloud-init
```

---

## Storage Optimization

### 0.3.7: Storage Optimization Tips

Optimize storage usage for training environments.

#### Thin Provisioning

QCOW2 images support thin provisioning (sparse files):

```bash
# Create thin-provisioned image
qemu-img create -f qcow2 vm-disk.qcow2 20G

# Check actual disk usage
du -h vm-disk.qcow2
# Output: 196K (not 20G!)

# The image grows as data is written
```

**Benefits**:
- ✅ Only uses space for actual data
- ✅ Can over-provision (create more VMs than physical space)
- ✅ Fast image creation

#### Copy-on-Write (Backing Images)

Use backing images to share a base image:

```bash
# Base image (read-only, shared)
BASE=/var/lib/libvirt/images/ubuntu-22.04-base.qcow2

# Create VM images backed by base
qemu-img create -f qcow2 -F qcow2 -b $BASE vm1.qcow2 20G
qemu-img create -f qcow2 -F qcow2 -b $BASE vm2.qcow2 20G
qemu-img create -f qcow2 -F qcow2 -b $BASE vm3.qcow2 20G

# Each VM image only stores differences from base
du -h vm*.qcow2
# vm1.qcow2: 196K
# vm2.qcow2: 196K
# vm3.qcow2: 196K
```

**Storage Savings**:
- Without backing: 3 VMs × 2 GB = 6 GB
- With backing: 2 GB (base) + 3 × 200 KB = ~2 GB
- **Savings: 67%**

#### Image Compression

Compress images to save space:

```bash
# Compress existing image
qemu-img convert -O qcow2 -c \
  ubuntu-22.04-base.qcow2 \
  ubuntu-22.04-base-compressed.qcow2

# Compare sizes
ls -lh ubuntu-22.04-base*.qcow2
```

**Trade-offs**:
- ✅ Smaller disk usage
- ⚠️ Slightly slower I/O
- ⚠️ Cannot use as backing image

#### Disk Space Monitoring

Monitor disk usage during training:

```bash
# Check libvirt pool usage
virsh pool-info default

# Check individual images
du -sh /var/lib/libvirt/images/*

# Find large images
find /var/lib/libvirt/images -type f -size +5G

# Check available space
df -h /var/lib/libvirt/images
```

#### Cleanup Strategies

**Remove Unused Images**:
```bash
# List all images
virsh vol-list default

# Delete unused image
virsh vol-delete --pool default vm-old.qcow2
```

**Compact Images**:
```bash
# Reclaim unused space (VM must be shut down)
virt-sparsify --in-place /var/lib/libvirt/images/vm1.qcow2
```

**Automated Cleanup Script**:
```bash
#!/bin/bash
# cleanup-images.sh - Remove old VM images

POOL_DIR="/var/lib/libvirt/images"
DAYS_OLD=30

echo "Finding images older than $DAYS_OLD days..."

find $POOL_DIR -name "*.qcow2" -type f -mtime +$DAYS_OLD | while read img; do
  # Check if image is in use
  if ! virsh domblklist --all | grep -q "$img"; then
    echo "Removing: $img"
    sudo rm "$img"
  else
    echo "Skipping (in use): $img"
  fi
done

echo "Cleanup complete!"
```

#### Storage Best Practices

1. **Use Backing Images**: Share base images across VMs
2. **Thin Provisioning**: Let images grow as needed
3. **Regular Cleanup**: Remove unused images weekly
4. **Monitor Usage**: Check disk space before creating VMs
5. **Compress Archives**: Compress images for long-term storage
6. **Separate Storage**: Use dedicated partition for libvirt images

---

## Troubleshooting

### 0.3.8: Troubleshooting Image Boot Issues

Common issues and solutions when working with base images.

#### Issue 1: Image Won't Boot

**Symptoms**:
- VM starts but doesn't boot
- Black screen or kernel panic
- "No bootable device" error

**Solutions**:

```bash
# Check image integrity
qemu-img check /var/lib/libvirt/images/ubuntu-22.04-base.qcow2

# Verify image format
qemu-img info /var/lib/libvirt/images/ubuntu-22.04-base.qcow2

# Try booting with more verbose output
virt-install \
  --name test-boot \
  --memory 2048 \
  --vcpus 2 \
  --disk path=/var/lib/libvirt/images/ubuntu-22.04-base.qcow2 \
  --import \
  --os-variant ubuntu22.04 \
  --graphics none \
  --console pty,target_type=serial \
  --debug

# Check VM logs
sudo tail -f /var/log/libvirt/qemu/test-boot.log
```

#### Issue 2: Cannot Login to VM

**Symptoms**:
- VM boots but login fails
- "Access denied" or "Permission denied"
- SSH connection refused

**Solutions**:

**For Cloud Images**:
```bash
# Cloud images require cloud-init for user creation
# Ensure cloud-init disk is attached

# Or set password using virt-customize
sudo virt-customize -a ubuntu-22.04-base.qcow2 \
  --root-password password:training123

# Or add SSH key
sudo virt-customize -a ubuntu-22.04-base.qcow2 \
  --ssh-inject ubuntu:file:/home/user/.ssh/id_rsa.pub
```

**For Console Access**:
```bash
# Enable serial console
sudo virt-customize -a ubuntu-22.04-base.qcow2 \
  --run-command 'systemctl enable serial-getty@ttyS0.service'
```

#### Issue 3: Network Not Working

**Symptoms**:
- No network connectivity inside VM
- Cannot ping external hosts
- DNS resolution fails

**Solutions**:

```bash
# Check libvirt network is running
virsh net-list --all

# Start default network if stopped
virsh net-start default
virsh net-autostart default

# Check VM network interface
virsh domiflist vm-name

# Inside VM, check network configuration
ip addr show
ip route show
cat /etc/resolv.conf

# Restart networking (Ubuntu)
sudo systemctl restart systemd-networkd

# Restart networking (Alpine)
sudo rc-service networking restart
```

#### Issue 4: Cloud-Init Not Running

**Symptoms**:
- Users not created
- SSH keys not added
- Packages not installed

**Solutions**:

```bash
# Check cloud-init status (inside VM)
cloud-init status

# View cloud-init logs
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log

# Check cloud-init configuration
sudo cloud-init query -a

# Re-run cloud-init (for testing)
sudo cloud-init clean
sudo reboot
```

**Verify Cloud-Init Disk**:
```bash
# Check if cloud-init disk is attached
virsh domblklist vm-name

# Should show something like:
# Target     Source
# ------------------------------------------------
# vda        /var/lib/libvirt/images/vm.qcow2
# vdb        /var/lib/libvirt/images/cloudinit.iso
```

#### Issue 5: Slow Boot Times

**Symptoms**:
- VM takes > 1 minute to boot
- Long delays during boot
- Timeouts waiting for services

**Solutions**:

```bash
# Check boot time (inside VM)
systemd-analyze

# Identify slow services
systemd-analyze blame

# Disable unnecessary services
sudo systemctl disable snapd
sudo systemctl disable unattended-upgrades

# For Alpine, check OpenRC services
rc-status
```

#### Issue 6: Disk Space Issues

**Symptoms**:
- "No space left on device"
- Image creation fails
- VM won't start

**Solutions**:

```bash
# Check available space
df -h /var/lib/libvirt/images

# Check image sizes
du -sh /var/lib/libvirt/images/*

# Remove unused images
virsh vol-list default
virsh vol-delete --pool default unused-image.qcow2

# Compact images to reclaim space
virt-sparsify --in-place /var/lib/libvirt/images/vm.qcow2
```

#### Issue 7: Permission Denied Errors

**Symptoms**:
- "Permission denied" when creating VMs
- Cannot access image files
- Libvirt errors about file access

**Solutions**:

```bash
# Fix image permissions
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/*.qcow2
sudo chmod 644 /var/lib/libvirt/images/*.qcow2

# Fix directory permissions
sudo chmod 755 /var/lib/libvirt/images

# Check SELinux context (RHEL/CentOS)
sudo restorecon -R /var/lib/libvirt/images

# Add user to libvirt group
sudo usermod -a -G libvirt $USER
newgrp libvirt
```

#### Issue 8: Image Corruption

**Symptoms**:
- "Image is corrupt" error
- Unexpected VM crashes
- Data loss

**Solutions**:

```bash
# Check image integrity
qemu-img check /var/lib/libvirt/images/vm.qcow2

# Attempt repair (DANGEROUS - backup first!)
qemu-img check -r all /var/lib/libvirt/images/vm.qcow2

# If repair fails, restore from backup
cp /backup/vm.qcow2 /var/lib/libvirt/images/vm.qcow2

# Or recreate from base image
qemu-img create -f qcow2 -F qcow2 \
  -b /var/lib/libvirt/images/ubuntu-22.04-base.qcow2 \
  /var/lib/libvirt/images/vm-new.qcow2 20G
```

#### Diagnostic Commands

**Check Libvirt Status**:
```bash
sudo systemctl status libvirtd
virsh version
virsh capabilities
```

**Check VM Status**:
```bash
virsh list --all
virsh dominfo vm-name
virsh domstate vm-name
```

**View VM Console**:
```bash
virsh console vm-name
# Press Ctrl+] to exit
```

**View VM Logs**:
```bash
sudo tail -f /var/log/libvirt/qemu/vm-name.log
```

**Check QEMU Process**:
```bash
ps aux | grep qemu
```

#### Getting Help

If issues persist:

1. **Check Documentation**: Review [libvirt-setup.md](libvirt-setup.md)
2. **Search Logs**: Look for errors in `/var/log/libvirt/`
3. **Community Forums**: Ask on libvirt mailing list or forums
4. **GitHub Issues**: Report bugs in training repository
5. **Instructor Support**: Contact course instructor

---

## Quick Reference

### Essential Commands

```bash
# Download Ubuntu cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Download Alpine cloud image
wget https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/cloud/alpine-cloud-3.19.0-x86_64.qcow2

# Copy to libvirt pool
sudo cp image.img /var/lib/libvirt/images/base.qcow2

# Resize image
sudo qemu-img resize /var/lib/libvirt/images/base.qcow2 20G

# Create backing image
qemu-img create -f qcow2 -F qcow2 -b base.qcow2 vm.qcow2 20G

# Verify image
qemu-img info base.qcow2
qemu-img check base.qcow2

# Customize image
sudo virt-customize -a base.qcow2 --root-password password:training123

# Test boot
virt-install --name test --memory 2048 --vcpus 2 --disk path=base.qcow2 --import
```

### Storage Locations

- **Downloaded Images**: `~/libvirt-images/`
- **Libvirt Pool**: `/var/lib/libvirt/images/`
- **Cloud-Init Configs**: `~/cloud-init/`
- **VM Logs**: `/var/log/libvirt/qemu/`

### Recommended Image Sizes

| Use Case | Virtual Size | Actual Usage |
|----------|--------------|--------------|
| Basic VM | 10 GB | 2-3 GB |
| Development VM | 20 GB | 5-8 GB |
| Database VM | 30 GB | 10-15 GB |
| Training Lab | 15 GB | 3-5 GB |

---

## Next Steps

After preparing your base images:

1. **Verify Setup**: Complete the [Image Verification Checklist](#image-verification)
2. **Test Creation**: Create a test VM using Terraform
3. **Start Learning**: Begin with [TF-101: Introduction to IaC](../TF-100-fundamentals/TF-101-intro-basics/README.md)
4. **Explore Packer**: Learn image building in [PKR-100 series](../PKR-100-fundamentals/README.md)

---

## Additional Resources

- **Ubuntu Cloud Images**: https://cloud-images.ubuntu.com/
- **Alpine Linux**: https://alpinelinux.org/downloads/
- **Cloud-Init Documentation**: https://cloudinit.readthedocs.io/
- **Libvirt Documentation**: https://libvirt.org/docs.html
- **QEMU Documentation**: https://www.qemu.org/documentation/

---

**Document Version**: 1.0  
**Last Updated**: 2026-02-26  
**Maintainer**: Hashi-Training Project