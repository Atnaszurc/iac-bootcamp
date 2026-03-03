# TF-103: Infrastructure Resources

**Course**: TF-100 Terraform Fundamentals  
**Module**: TF-103  
**Duration**: 2 hours  
**Prerequisites**: TF-102 (Variables, Loops & Functions)  
**Difficulty**: Beginner

---

## 📋 Overview

This course teaches you how to create and manage real infrastructure resources using Terraform and Libvirt. You'll build complete infrastructure stacks including networks, security configurations, storage, and virtual machines with proper dependencies and relationships.

**What You'll Build**: By the end of this course, you'll deploy a complete local infrastructure stack with networks, storage, security rules, and multiple VMs - all managed as code!

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- ✅ **Create** virtual networks with proper CIDR configuration
- ✅ **Configure** storage pools and volumes for VMs
- ✅ **Deploy** virtual machines (domains) with Libvirt
- ✅ **Integrate** cloud-init for VM initialization
- ✅ **Implement** security groups and firewall rules
- ✅ **Understand** resource dependencies and ordering
- ✅ **Manage** resource lifecycles (create, update, destroy)
- ✅ **Build** complete infrastructure stacks
- ✅ **Troubleshoot** common Libvirt issues
- ✅ **Apply** infrastructure best practices

---

## 📚 Course Structure

This course is organized into **3 progressive sections** that build a complete infrastructure stack.

### Section 1: Networks 🌐
**Directory**: [`1-networks/`](./1-networks/)  
**Duration**: 40 minutes

**Topics Covered**:
- Virtual network creation with Libvirt
- CIDR block configuration (10.0.0.0/16)
- Subnet management
- DHCP and DNS configuration
- Network isolation and segmentation
- Network resource attributes and outputs

**What You'll Learn**:
- How to create isolated virtual networks
- How to configure IP address ranges
- How to enable DHCP for automatic IP assignment
- How to reference network resources in other configurations

**[→ Start Section 1: Networks](./1-networks/README.md)**

---

### Section 2: Security 🔒
**Directory**: [`2-security/`](./2-security/)  
**Duration**: 30 minutes

**Topics Covered**:
- Security group creation
- Firewall rule configuration
- Inbound and outbound rules
- Port management (SSH, HTTP, HTTPS)
- Protocol restrictions (TCP, UDP, ICMP)
- Security best practices

**What You'll Learn**:
- How to create security groups
- How to define firewall rules
- How to restrict access by port and protocol
- How to apply security-first principles

**[→ Start Section 2: Security](./2-security/README.md)**

---

### Section 3: Virtual Machines 💻
**Directory**: [`3-virtual-machines/`](./3-virtual-machines/)  
**Duration**: 50 minutes

**Topics Covered**:
- Storage pool and volume creation
- VM (domain) resource configuration
- Base image selection and management
- CPU and memory allocation
- Disk attachment and sizing
- Network interface configuration
- Cloud-init integration for initialization
- Resource dependencies (implicit and explicit)
- Complete infrastructure stack assembly

**What You'll Learn**:
- How to create storage for VMs
- How to deploy VMs with proper configuration
- How to use cloud-init for VM setup
- How to connect VMs to networks and security groups
- How to manage resource dependencies
- How to build complete infrastructure stacks

**[→ Start Section 3: Virtual Machines](./3-virtual-machines/README.md)**

---

## 🚀 Quick Start

### Prerequisites Check

Before starting, ensure you have:

```bash
# 1. Terraform installed
terraform version
# Should show v1.9.0 or higher

# 2. Libvirt installed and running
sudo systemctl status libvirtd  # Linux
brew services list | grep libvirt  # macOS

# 3. Base images prepared
ls ~/libvirt-images/
# Should have ubuntu-22.04-base.qcow2 or alpine-base.qcow2
```

**Need help?** See [Libvirt Setup Guide](../../../docs/libvirt-setup.md) and [Base Image Preparation](../../../docs/base-image-preparation.md)

---

### Learning Path

**Option 1: Sequential (Recommended)**

Build infrastructure layer by layer:

```bash
# Step 1: Create Network
cd 1-networks/
cat README.md
cd example/
terraform init
terraform apply

# Step 2: Add Security
cd ../../2-security/
cat README.md
cd example/
terraform init
terraform apply

# Step 3: Deploy VMs
cd ../../3-virtual-machines/
cat README.md
cd example/
terraform init
terraform apply
```

**Option 2: Jump to Topic**

Already familiar with some concepts? Jump directly:

- **Need networking basics?** → [`1-networks/`](./1-networks/)
- **Want to secure infrastructure?** → [`2-security/`](./2-security/)
- **Ready to deploy VMs?** → [`3-virtual-machines/`](./3-virtual-machines/)

---

## 🏗️ What You'll Build

### Complete Infrastructure Stack

```
┌─────────────────────────────────────────────────────┐
│                  Libvirt Host                       │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  Virtual Network: 10.0.0.0/16                 │ │
│  │  ├── DHCP: Enabled                            │ │
│  │  └── DNS: Enabled                             │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  Security Group                               │ │
│  │  ├── Allow SSH (22/tcp)                       │ │
│  │  ├── Allow HTTP (80/tcp)                      │ │
│  │  └── Allow HTTPS (443/tcp)                    │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  Storage Pool: /var/lib/libvirt/images       │ │
│  │  └── Volumes: 20GB each                       │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐ │
│  │   VM-1       │  │   VM-2       │  │   VM-3   │ │
│  │ 2 CPU, 2GB   │  │ 2 CPU, 2GB   │  │ 2 CPU    │ │
│  │ 10.0.0.10    │  │ 10.0.0.11    │  │ 10.0.0.12│ │
│  │ Ubuntu 22.04 │  │ Ubuntu 22.04 │  │ Alpine   │ │
│  └──────────────┘  └──────────────┘  └──────────┘ │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Resource Dependencies

Terraform automatically manages the creation order:

```
1. Network (libvirt_network)
   ↓
2. Storage Pool (libvirt_pool)
   ↓
3. Storage Volumes (libvirt_volume)
   ↓
4. Cloud-Init Disks (libvirt_cloudinit_disk)
   ↓
5. Virtual Machines (libvirt_domain)
   ├── Depends on: Network
   ├── Depends on: Volumes
   └── Depends on: Cloud-Init
```

---

## 📖 Key Concepts

### 1. Libvirt Resources

#### Networks
```hcl
resource "libvirt_network" "main" {
  name      = "terraform-network"
  mode      = "nat"
  domain    = "terraform.local"
  addresses = ["10.0.0.0/16"]
  
  dhcp {
    enabled = true
  }
  
  dns {
    enabled = true
  }
}
```

**Learn more**: [Section 1: Networks](./1-networks/README.md)

---

#### Storage Pools and Volumes
```hcl
resource "libvirt_pool" "main" {
  name = "terraform-pool"
  type = "dir"
  path = "/var/lib/libvirt/images/terraform"
}

resource "libvirt_volume" "vm_disk" {
  name   = "vm-disk.qcow2"
  pool   = libvirt_pool.main.name
  format = "qcow2"
  size   = 21474836480  # 20 GB in bytes
}
```

**Learn more**: [Section 3: Virtual Machines](./3-virtual-machines/README.md)

---

#### Virtual Machines (Domains)
```hcl
resource "libvirt_domain" "vm" {
  name   = "terraform-vm"
  memory = "2048"
  vcpu   = 2
  
  disk {
    volume_id = libvirt_volume.vm_disk.id
  }
  
  network_interface {
    network_id = libvirt_network.main.id
  }
  
  cloudinit = libvirt_cloudinit_disk.init.id
}
```

**Learn more**: [Section 3: Virtual Machines](./3-virtual-machines/README.md)

---

### 2. Cloud-Init Integration

Cloud-init automates VM initialization:

```yaml
#cloud-config
hostname: terraform-vm-01

users:
  - name: student
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2E... your-key

packages:
  - vim
  - curl
  - git

runcmd:
  - echo "VM initialized by Terraform" > /etc/motd
```

```hcl
data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-init.yaml")
}

resource "libvirt_cloudinit_disk" "init" {
  name      = "cloudinit.iso"
  user_data = data.template_file.cloud_init.rendered
}
```

**Learn more**: [Section 3: Virtual Machines](./3-virtual-machines/README.md)

---

### 3. Resource Dependencies

#### Implicit Dependencies

Terraform automatically detects dependencies through resource references:

```hcl
resource "libvirt_network" "main" {
  name = "my-network"
}

resource "libvirt_domain" "vm" {
  name = "my-vm"
  
  network_interface {
    network_id = libvirt_network.main.id  # Implicit dependency
  }
}
```

Terraform creates the network before the VM automatically!

#### Explicit Dependencies

Use `depends_on` when dependencies aren't obvious:

```hcl
resource "libvirt_domain" "vm" {
  name = "my-vm"
  
  depends_on = [
    libvirt_network.main,
    libvirt_pool.storage
  ]
}
```

**Learn more**: [Section 3: Virtual Machines](./3-virtual-machines/README.md)

---

### 4. Resource Lifecycle

Control how Terraform manages resources:

```hcl
resource "libvirt_domain" "vm" {
  name = "my-vm"
  
  lifecycle {
    # Prevent accidental deletion
    prevent_destroy = true
    
    # Create new before destroying old
    create_before_destroy = true
    
    # Ignore changes to specific attributes
    ignore_changes = [
      disk,
      network_interface
    ]
  }
}
```

**Common Lifecycle Options**:
- `create_before_destroy` - Create replacement before destroying original
- `prevent_destroy` - Prevent accidental deletion
- `ignore_changes` - Ignore changes to specific attributes
- `replace_triggered_by` - Force replacement when other resources change

**Learn more**: [Section 3: Virtual Machines](./3-virtual-machines/README.md)

---

## 🧪 Hands-On Labs

### Lab 1: Build Complete VM Infrastructure

**Objective**: Create a full infrastructure stack from scratch

**Duration**: 30 minutes

**Steps**:

1. **Create Network**
```hcl
resource "libvirt_network" "lab" {
  name      = "lab-network"
  mode      = "nat"
  addresses = ["192.168.100.0/24"]
  dhcp {
    enabled = true
  }
}
```

2. **Create Storage**
```hcl
resource "libvirt_pool" "lab" {
  name = "lab-pool"
  type = "dir"
  path = "/var/lib/libvirt/images/lab"
}

resource "libvirt_volume" "lab_disk" {
  name   = "lab-vm.qcow2"
  pool   = libvirt_pool.lab.name
  source = "/var/lib/libvirt/images/ubuntu-22.04-base.qcow2"
  format = "qcow2"
}
```

3. **Deploy VM**
```hcl
resource "libvirt_domain" "lab_vm" {
  name   = "lab-vm"
  memory = "2048"
  vcpu   = 2
  
  disk {
    volume_id = libvirt_volume.lab_disk.id
  }
  
  network_interface {
    network_id = libvirt_network.lab.id
  }
}
```

4. **Apply and Test**
```bash
terraform init
terraform plan
terraform apply

# Get VM IP
virsh domifaddr lab-vm

# SSH to VM (if cloud-init configured)
ssh student@<vm-ip>
```

---

### Lab 2: Multi-VM Deployment

**Objective**: Deploy multiple VMs with loops

**Duration**: 25 minutes

```hcl
variable "vm_count" {
  type    = number
  default = 3
}

resource "libvirt_volume" "vm_disks" {
  count  = var.vm_count
  name   = "vm-${count.index + 1}.qcow2"
  pool   = libvirt_pool.main.name
  source = "/var/lib/libvirt/images/ubuntu-22.04-base.qcow2"
  format = "qcow2"
}

resource "libvirt_domain" "vms" {
  count  = var.vm_count
  name   = "terraform-vm-${count.index + 1}"
  memory = "2048"
  vcpu   = 2
  
  disk {
    volume_id = libvirt_volume.vm_disks[count.index].id
  }
  
  network_interface {
    network_id = libvirt_network.main.id
  }
}

output "vm_ips" {
  value = [for vm in libvirt_domain.vms : vm.network_interface[0].addresses[0]]
}
```

**Challenge**: Modify to use `for_each` instead of `count` for better stability!

---

### Lab 3: Cloud-Init Configuration

**Objective**: Use cloud-init to configure VMs automatically

**Duration**: 25 minutes

Create `cloud-init.yaml`:
```yaml
#cloud-config
hostname: ${hostname}

users:
  - name: ${username}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_key}

packages:
  - nginx
  - curl

runcmd:
  - systemctl enable nginx
  - systemctl start nginx
  - echo "Hello from ${hostname}" > /var/www/html/index.html
```

Create `main.tf`:
```hcl
data "template_file" "cloud_init" {
  count = var.vm_count
  
  template = file("${path.module}/cloud-init.yaml")
  
  vars = {
    hostname = "web-${count.index + 1}"
    username = "admin"
    ssh_key  = file("~/.ssh/id_rsa.pub")
  }
}

resource "libvirt_cloudinit_disk" "init" {
  count     = var.vm_count
  name      = "cloudinit-${count.index}.iso"
  user_data = data.template_file.cloud_init[count.index].rendered
}

resource "libvirt_domain" "web_servers" {
  count  = var.vm_count
  name   = "web-${count.index + 1}"
  memory = "2048"
  vcpu   = 2
  
  cloudinit = libvirt_cloudinit_disk.init[count.index].id
  
  # ... rest of configuration
}
```

**Test**: After deployment, curl each VM's IP to see the custom message!

---

## 🔧 Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: "Error creating libvirt network"

**Symptoms**:
```
Error: Error creating libvirt network: virError(Code=9, Domain=19, Message='operation failed: network 'terraform-network' already exists')
```

**Causes**:
- Network with same name already exists
- Previous Terraform run didn't clean up
- Manual network creation conflicts

**Solutions**:

```bash
# List existing networks
virsh net-list --all

# Delete conflicting network
virsh net-destroy terraform-network
virsh net-undefine terraform-network

# Or use a different name in your configuration
resource "libvirt_network" "main" {
  name = "terraform-network-${random_id.network.hex}"
}
```

---

#### Issue 2: "Error creating libvirt domain"

**Symptoms**:
```
Error: Error creating libvirt domain: virError(Code=1, Domain=10, Message='internal error: process exited while connecting to monitor')
```

**Causes**:
- Insufficient system resources
- Invalid disk image
- Missing dependencies
- Incorrect configuration

**Solutions**:

```bash
# 1. Check system resources
free -h  # Check available RAM
df -h    # Check disk space

# 2. Verify image exists and is valid
ls -lh /var/lib/libvirt/images/
qemu-img info /var/lib/libvirt/images/ubuntu-22.04-base.qcow2

# 3. Check libvirt logs
sudo journalctl -u libvirtd -n 50

# 4. Verify QEMU/KVM is working
sudo systemctl status libvirtd
lsmod | grep kvm

# 5. Test with minimal configuration
resource "libvirt_domain" "test" {
  name   = "test-vm"
  memory = "512"  # Minimal memory
  vcpu   = 1
  
  disk {
    file = "/var/lib/libvirt/images/test.qcow2"
  }
}
```

---

#### Issue 3: "Cannot access VM via network"

**Symptoms**:
- VM created successfully
- Cannot ping or SSH to VM
- No IP address assigned

**Causes**:
- Network not properly configured
- DHCP not enabled
- Firewall blocking access
- Cloud-init not running

**Solutions**:

```bash
# 1. Check VM is running
virsh list --all

# 2. Get VM network info
virsh domifaddr vm-name

# 3. Check network configuration
virsh net-list --all
virsh net-info terraform-network

# 4. Verify DHCP is enabled
virsh net-dumpxml terraform-network | grep dhcp

# 5. Access VM console directly
virsh console vm-name
# Press Ctrl+] to exit

# 6. Check cloud-init status (inside VM)
cloud-init status
sudo cat /var/log/cloud-init.log
```

---

#### Issue 4: "Volume already exists"

**Symptoms**:
```
Error: Error creating libvirt volume: virError(Code=90, Domain=18, Message='storage volume 'vm-disk.qcow2' exists already')
```

**Solutions**:

```bash
# List volumes in pool
virsh vol-list default

# Delete existing volume
virsh vol-delete --pool default vm-disk.qcow2

# Or use unique names
resource "libvirt_volume" "disk" {
  name = "vm-disk-${random_id.disk.hex}.qcow2"
}

# Or import existing volume
terraform import libvirt_volume.disk default/vm-disk.qcow2
```

---

#### Issue 5: "Permission denied" errors

**Symptoms**:
```
Error: Error creating libvirt domain: virError(Code=1, Domain=10, Message='Permission denied')
```

**Causes**:
- Incorrect file permissions
- SELinux blocking access
- User not in libvirt group

**Solutions**:

```bash
# 1. Fix file permissions
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/*.qcow2
sudo chmod 644 /var/lib/libvirt/images/*.qcow2

# 2. Add user to libvirt group
sudo usermod -a -G libvirt $USER
newgrp libvirt

# 3. Check SELinux (RHEL/CentOS)
sudo setenforce 0  # Temporary
sudo restorecon -R /var/lib/libvirt/images

# 4. Verify libvirt socket permissions
ls -l /var/run/libvirt/libvirt-sock
```

---

#### Issue 6: "Slow VM performance"

**Symptoms**:
- VM runs but is very slow
- High CPU usage on host
- Sluggish response

**Solutions**:

```hcl
# Enable KVM acceleration
resource "libvirt_domain" "vm" {
  name = "my-vm"
  
  # Use KVM (hardware virtualization)
  type = "kvm"
  
  # Optimize CPU
  vcpu = 2
  cpu {
    mode = "host-passthrough"
  }
  
  # Use virtio for better performance
  disk {
    volume_id = libvirt_volume.disk.id
    scsi      = false
  }
  
  network_interface {
    network_id = libvirt_network.main.id
    model      = "virtio"
  }
}
```

---

### Diagnostic Commands

```bash
# Check Libvirt status
sudo systemctl status libvirtd
virsh version

# List all resources
virsh list --all                    # VMs
virsh net-list --all                # Networks
virsh pool-list --all               # Storage pools
virsh vol-list --pool default       # Volumes

# Get detailed info
virsh dominfo vm-name               # VM details
virsh net-info network-name         # Network details
virsh pool-info pool-name           # Pool details

# View logs
sudo journalctl -u libvirtd -f      # Follow libvirt logs
virsh console vm-name               # VM console

# Resource usage
virsh domstats vm-name              # VM statistics
virsh pool-info default             # Pool usage
```

---

## ✅ Checkpoint Quiz

### Question 1: Resource Dependencies

**How does Terraform know to create the network before the VM?**

A) You must use depends_on explicitly  
B) Terraform creates resources alphabetically  
C) Terraform detects the dependency through resource references  
D) You must specify the order in a separate file

<details>
<summary>Show Answer</summary>

**C) Terraform detects the dependency through resource references**

When you reference `libvirt_network.main.id` in the VM configuration, Terraform automatically knows the network must be created first. This is called an implicit dependency.
</details>

---

### Question 2: Storage Volumes

**What format should you use for Libvirt volumes?**

A) raw  
B) qcow2  
C) vmdk  
D) vdi

<details>
<summary>Show Answer</summary>

**B) qcow2**

QCOW2 (QEMU Copy-On-Write version 2) is the recommended format for Libvirt. It supports thin provisioning, snapshots, and compression. While `raw` works, qcow2 is more efficient.
</details>

---

### Question 3: Cloud-Init

**What does cloud-init do?**

A) Creates cloud infrastructure  
B) Initializes and configures VMs on first boot  
C) Manages cloud provider credentials  
D) Monitors cloud resources

<details>
<summary>Show Answer</summary>

**B) Initializes and configures VMs on first boot**

Cloud-init is a standard for VM initialization. It runs on first boot to configure users, install packages, run scripts, and set up the VM according to your specifications.
</details>

---

### Question 4: Resource Lifecycle

**What does `create_before_destroy = true` do?**

A) Creates resources in alphabetical order  
B) Creates new resource before destroying the old one  
C) Prevents resource deletion  
D) Destroys all resources before creating new ones

<details>
<summary>Show Answer</summary>

**B) Creates new resource before destroying the old one**

This lifecycle option ensures zero downtime during updates. Terraform creates the replacement resource first, then destroys the old one. Useful for resources that can't have downtime.
</details>

---

### Question 5: Networking

**What does "mode = nat" mean for a Libvirt network?**

A) Network is isolated with no external access  
B) Network uses NAT to access external networks  
C) Network is bridged to host network  
D) Network is disabled

<details>
<summary>Show Answer</summary>

**B) Network uses NAT to access external networks**

NAT (Network Address Translation) mode allows VMs to access external networks (internet) through the host, but external networks cannot directly access the VMs. This is the most common mode for development.
</details>

---

### Question 6: Troubleshooting

**Which command shows the IP address of a VM?**

A) `virsh list vm-name`  
B) `virsh domifaddr vm-name`  
C) `virsh net-list vm-name`  
D) `virsh ip vm-name`

<details>
<summary>Show Answer</summary>

**B) `virsh domifaddr vm-name`**

This command displays the network interfaces and IP addresses assigned to a VM. Useful for finding the IP to SSH into your VM.
</details>

---

## 📋 Best Practices

### 1. Network Design

✅ **DO**:
- Use private IP ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
- Enable DHCP for automatic IP assignment
- Use descriptive network names
- Document CIDR blocks

❌ **DON'T**:
- Use public IP ranges
- Overlap IP ranges between networks
- Disable DHCP without static IP configuration

### 2. Storage Management

✅ **DO**:
- Use qcow2 format for efficiency
- Create dedicated storage pools
- Use backing images for base images
- Monitor disk usage

❌ **DON'T**:
- Store volumes in system directories
- Use raw format unless necessary
- Forget to clean up unused volumes

### 3. VM Configuration

✅ **DO**:
- Use cloud-init for initialization
- Set appropriate CPU and memory
- Use virtio drivers for performance
- Enable KVM acceleration
- Tag resources for identification

❌ **DON'T**:
- Over-allocate resources
- Forget to configure networking
- Skip cloud-init configuration
- Use default passwords

### 4. Resource Management

✅ **DO**:
- Use variables for configuration
- Implement proper dependencies
- Use lifecycle rules when needed
- Clean up resources when done
- Version control your configurations

❌ **DON'T**:
- Hard-code values
- Ignore resource dependencies
- Leave unused resources running
- Skip documentation

---

## 🔗 Additional Resources

### Official Documentation
- [Libvirt Provider](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs)
- [Terraform Resource Dependencies](https://developer.hashicorp.com/terraform/language/resources/behavior#resource-dependencies)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Libvirt Documentation](https://libvirt.org/docs.html)

### Guides
- [Libvirt Setup Guide](../../../docs/libvirt-setup.md)
- [Base Image Preparation](../../../docs/base-image-preparation.md)
- [Networking Basics](https://www.cloudflare.com/learning/network-layer/what-is-a-computer-network/)

### Next Steps
After completing TF-103, continue to:
- **[TF-104: State Management & CLI](../TF-104-state-cli/README.md)** - Master Terraform state and CLI commands

---

## 📊 Progress Tracking

Use this checklist to track your progress:

- [ ] **Section 1: Networks** - Virtual networks, CIDR, DHCP
- [ ] **Section 2: Security** - Security groups, firewall rules
- [ ] **Section 3: Virtual Machines** - Storage, VMs, cloud-init
- [ ] **Lab 1**: Build complete VM infrastructure
- [ ] **Lab 2**: Multi-VM deployment
- [ ] **Lab 3**: Cloud-init configuration
- [ ] **Checkpoint Quiz**: Test your understanding
- [ ] **Troubleshooting**: Practice diagnostic commands

---

## 🎓 Summary

In this module, you learned:

✅ **Networks** - Create isolated virtual networks with DHCP  
✅ **Storage** - Manage storage pools and volumes  
✅ **Security** - Implement firewall rules and security groups  
✅ **Virtual Machines** - Deploy and configure VMs  
✅ **Cloud-Init** - Automate VM initialization  
✅ **Dependencies** - Understand resource relationships  
✅ **Lifecycle** - Control resource creation and destruction  
✅ **Troubleshooting** - Diagnose and fix common issues

**You're now ready to build complete infrastructure stacks with Terraform!**

---

**Course**: TF-100 Terraform Fundamentals  
**Module**: TF-103  
**Version**: 1.0  
**Last Updated**: 2026-02-26

**Ready to build real infrastructure? Let's start with networks!** 🚀

**[→ Begin with Section 1: Networks](./1-networks/README.md)**
