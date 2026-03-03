# Libvirt Provider Setup Guide

**Purpose**: This guide will help you install and configure Libvirt for use with Terraform in the hashi-training course.

**Why Libvirt?**: Libvirt provides a free, local virtualization platform that lets you learn Terraform concepts without cloud costs. It creates real VMs on your machine, giving you a cloud-like experience locally.

---

## System Requirements

### Minimum Requirements
- **CPU**: 64-bit processor with virtualization support (Intel VT-x or AMD-V)
- **RAM**: 8 GB (16 GB recommended for running multiple VMs)
- **Disk Space**: 50 GB free space (for base images and VMs)
- **OS**: Linux, macOS, or Windows 10/11 with WSL2

### Recommended Requirements
- **CPU**: 4+ cores with virtualization enabled
- **RAM**: 16 GB or more
- **Disk Space**: 100 GB+ free space
- **SSD**: Solid-state drive for better VM performance

### Checking Virtualization Support

**Linux:**
```bash
# Check for virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo
# If output is > 0, virtualization is supported

# Check if KVM module is loaded
lsmod | grep kvm
```

**macOS:**
```bash
# macOS Intel Macs have virtualization enabled by default
sysctl -a | grep machdep.cpu.features | grep VMX
```

**Windows (PowerShell):**
```powershell
# Check virtualization support
Get-ComputerInfo | Select-Object HyperVisorPresent, HyperVRequirementVirtualizationFirmwareEnabled
```

---

## Installation Guide

### Linux Installation

#### Ubuntu/Debian

```bash
# Update package list
sudo apt update

# Install QEMU, KVM, and Libvirt
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils

# Install additional tools
sudo apt install -y virt-manager libvirt-dev

# Add your user to libvirt groups
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

# Start and enable libvirt service
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

# Verify installation
sudo systemctl status libvirtd
```

#### Fedora/RHEL/CentOS

```bash
# Install virtualization packages
sudo dnf install -y @virtualization

# Start and enable libvirt service
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

# Add your user to libvirt group
sudo usermod -aG libvirt $USER

# Verify installation
sudo systemctl status libvirtd
```

#### Arch Linux

```bash
# Install QEMU and Libvirt
sudo pacman -S qemu libvirt virt-manager dnsmasq bridge-utils

# Start and enable libvirt service
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

# Add your user to libvirt group
sudo usermod -aG libvirt $USER

# Verify installation
sudo systemctl status libvirtd
```

**Important**: After adding your user to groups, log out and log back in for changes to take effect.

---

### macOS Installation

#### Using Homebrew

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install QEMU
brew install qemu

# Install Libvirt
brew install libvirt

# Start libvirt service
brew services start libvirt

# Verify installation
brew services list | grep libvirt
```

#### Configuration for macOS

```bash
# Create libvirt configuration directory
mkdir -p ~/.config/libvirt

# Set libvirt URI for user session
echo 'export LIBVIRT_DEFAULT_URI="qemu:///session"' >> ~/.zshrc
# Or for bash users:
# echo 'export LIBVIRT_DEFAULT_URI="qemu:///session"' >> ~/.bash_profile

# Reload shell configuration
source ~/.zshrc  # or source ~/.bash_profile
```

**Note**: macOS uses QEMU in user mode (qemu:///session) rather than system mode due to permission restrictions.

---

### Windows Installation (WSL2)

#### Prerequisites

1. **Enable WSL2**:
```powershell
# Run in PowerShell as Administrator
wsl --install

# Restart your computer
```

2. **Install Ubuntu from Microsoft Store**:
   - Open Microsoft Store
   - Search for "Ubuntu 22.04 LTS"
   - Click "Get" to install

3. **Set WSL2 as default**:
```powershell
wsl --set-default-version 2
```

#### Install Libvirt in WSL2

```bash
# Open Ubuntu WSL2 terminal
# Update package list
sudo apt update

# Install QEMU, KVM, and Libvirt
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils

# Install additional tools
sudo apt install -y libvirt-dev

# Add your user to libvirt groups
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

# Start libvirt service
sudo service libvirtd start

# Verify installation
sudo service libvirtd status
```

#### Enable Nested Virtualization (Windows)

```powershell
# Run in PowerShell as Administrator
# For Intel processors:
bcdedit /set hypervisorlaunchtype auto

# Restart your computer
```

**Note**: WSL2 has some limitations with nested virtualization. Performance may be slower than native Linux.

---

## Network Configuration

### Default Network Setup

Libvirt creates a default NAT network automatically. Verify it exists:

```bash
# List all networks
virsh net-list --all

# Expected output should show 'default' network
# Name      State    Autostart   Persistent
# default   active   yes         yes
```

### Start Default Network

```bash
# If default network is not active, start it
virsh net-start default

# Enable autostart
virsh net-autostart default

# Verify network is running
virsh net-list
```

### Default Network Details

```bash
# View network configuration
virsh net-dumpxml default
```

The default network typically uses:
- **Network**: 192.168.122.0/24
- **Gateway**: 192.168.122.1
- **DHCP Range**: 192.168.122.2 - 192.168.122.254

### Creating Custom Networks (Optional)

```bash
# Create a custom network definition file
cat > custom-network.xml << 'EOF'
<network>
  <name>terraform-net</name>
  <forward mode='nat'/>
  <bridge name='virbr1' stp='on' delay='0'/>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.2' end='192.168.100.254'/>
    </dhcp>
  </ip>
</network>
EOF

# Define the network
virsh net-define custom-network.xml

# Start the network
virsh net-start terraform-net

# Enable autostart
virsh net-autostart terraform-net

# Verify
virsh net-list
```

---

## Verification Script

Save this script as `verify-libvirt.sh` and run it to verify your installation:

```bash
#!/bin/bash

echo "==================================="
echo "Libvirt Installation Verification"
echo "==================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo "⚠️  Please run as regular user, not root"
   exit 1
fi

# Check libvirt service
echo "1. Checking libvirt service..."
if systemctl is-active --quiet libvirtd 2>/dev/null || service libvirtd status >/dev/null 2>&1; then
    echo "✅ Libvirt service is running"
else
    echo "❌ Libvirt service is not running"
    echo "   Try: sudo systemctl start libvirtd"
    exit 1
fi

# Check virsh command
echo ""
echo "2. Checking virsh command..."
if command -v virsh &> /dev/null; then
    echo "✅ virsh command is available"
    VIRSH_VERSION=$(virsh --version)
    echo "   Version: $VIRSH_VERSION"
else
    echo "❌ virsh command not found"
    exit 1
fi

# Check user permissions
echo ""
echo "3. Checking user permissions..."
if groups | grep -q libvirt; then
    echo "✅ User is in libvirt group"
else
    echo "⚠️  User is not in libvirt group"
    echo "   Run: sudo usermod -aG libvirt $USER"
    echo "   Then log out and log back in"
fi

# Check KVM support (Linux only)
echo ""
echo "4. Checking KVM support..."
if [ -e /dev/kvm ]; then
    echo "✅ KVM is available"
    if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
        echo "✅ KVM is accessible"
    else
        echo "⚠️  KVM exists but may not be accessible"
        echo "   Check group membership: ls -l /dev/kvm"
    fi
else
    echo "⚠️  KVM not available (may be normal on macOS/WSL2)"
fi

# Check default network
echo ""
echo "5. Checking default network..."
if virsh net-list --all 2>/dev/null | grep -q "default"; then
    echo "✅ Default network exists"
    if virsh net-list 2>/dev/null | grep -q "default.*active"; then
        echo "✅ Default network is active"
    else
        echo "⚠️  Default network exists but is not active"
        echo "   Run: virsh net-start default"
    fi
else
    echo "❌ Default network not found"
    echo "   This may need to be created manually"
fi

# Check QEMU
echo ""
echo "6. Checking QEMU..."
if command -v qemu-system-x86_64 &> /dev/null; then
    echo "✅ QEMU is installed"
    QEMU_VERSION=$(qemu-system-x86_64 --version | head -n1)
    echo "   $QEMU_VERSION"
else
    echo "❌ QEMU not found"
fi

# Test connection
echo ""
echo "7. Testing libvirt connection..."
if virsh -c qemu:///system list >/dev/null 2>&1; then
    echo "✅ Can connect to qemu:///system"
elif virsh -c qemu:///session list >/dev/null 2>&1; then
    echo "✅ Can connect to qemu:///session (macOS mode)"
else
    echo "❌ Cannot connect to libvirt"
    exit 1
fi

# Summary
echo ""
echo "==================================="
echo "Verification Summary"
echo "==================================="
echo "✅ Libvirt is properly installed and configured!"
echo ""
echo "Next steps:"
echo "1. Install Terraform: https://developer.hashicorp.com/terraform/install"
echo "2. Install Terraform Libvirt provider"
echo "3. Start the training!"
echo ""
```

Make it executable and run:

```bash
chmod +x verify-libvirt.sh
./verify-libvirt.sh
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: "Failed to connect to libvirt"

**Solution 1**: Check if libvirt service is running
```bash
# Linux
sudo systemctl status libvirtd
sudo systemctl start libvirtd

# macOS
brew services list
brew services restart libvirt
```

**Solution 2**: Check user permissions
```bash
# Verify group membership
groups

# If libvirt group is missing, add it
sudo usermod -aG libvirt $USER

# Log out and log back in
```

**Solution 3**: Check connection URI
```bash
# Try different connection URIs
virsh -c qemu:///system list
virsh -c qemu:///session list

# Set default URI
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

---

#### Issue: "Permission denied" when accessing /dev/kvm

**Solution**:
```bash
# Check KVM permissions
ls -l /dev/kvm

# Add user to kvm group
sudo usermod -aG kvm $USER

# Verify kvm module is loaded
lsmod | grep kvm

# If not loaded, load it
sudo modprobe kvm
sudo modprobe kvm_intel  # For Intel CPUs
# OR
sudo modprobe kvm_amd    # For AMD CPUs
```

---

#### Issue: "Default network not found"

**Solution**:
```bash
# Create default network definition
cat > /tmp/default-network.xml << 'EOF'
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF

# Define and start the network
virsh net-define /tmp/default-network.xml
virsh net-start default
virsh net-autostart default
```

---

#### Issue: VMs are slow or unresponsive

**Solution 1**: Enable KVM acceleration
```bash
# Verify KVM is available
egrep -c '(vmx|svm)' /proc/cpuinfo

# Check if KVM module is loaded
lsmod | grep kvm

# Ensure VMs use KVM (not QEMU emulation)
# In Terraform, use: driver = "kvm"
```

**Solution 2**: Allocate more resources
```bash
# Check available resources
free -h
nproc

# Adjust VM resources in Terraform configuration
# - Reduce number of concurrent VMs
# - Allocate appropriate memory and CPUs
```

---

#### Issue: WSL2 nested virtualization not working

**Solution**:
```bash
# Check if nested virtualization is enabled
cat /proc/cpuinfo | grep -E "vmx|svm"

# If not available, you may need to:
# 1. Enable nested virtualization in Windows
# 2. Use QEMU emulation mode (slower)
# 3. Consider using native Linux or macOS
```

**Alternative**: Use QEMU without KVM
```bash
# In Terraform, use TCG (QEMU emulation)
# This is slower but works without KVM
```

---

#### Issue: "Network 'default' is not active"

**Solution**:
```bash
# Start the default network
virsh net-start default

# Enable autostart
virsh net-autostart default

# Verify
virsh net-list --all
```

---

#### Issue: macOS "Operation not permitted"

**Solution**:
```bash
# Use session mode instead of system mode
export LIBVIRT_DEFAULT_URI="qemu:///session"

# Add to shell profile
echo 'export LIBVIRT_DEFAULT_URI="qemu:///session"' >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

---

### Getting Help

If you encounter issues not covered here:

1. **Check logs**:
   ```bash
   # Linux
   sudo journalctl -u libvirtd -f
   
   # View libvirt logs
   sudo tail -f /var/log/libvirt/libvirtd.log
   ```

2. **Verify configuration**:
   ```bash
   virsh version
   virsh capabilities
   ```

3. **Community resources**:
   - Libvirt documentation: https://libvirt.org/docs.html
   - Terraform Libvirt provider: https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs
   - Training repository issues: [Link to your repo]

---

## Next Steps

Once Libvirt is installed and verified:

1. ✅ **Install Terraform**: Follow the [Terraform installation guide](https://developer.hashicorp.com/terraform/install)

2. ✅ **Download base images**: See `docs/base-images.md` for Ubuntu cloud image setup

3. ✅ **Start the training**: Begin with Terraform 1, Block 1 - Fundamentals

---

## Quick Reference

### Essential Commands

```bash
# Service management
sudo systemctl start libvirtd
sudo systemctl status libvirtd

# List VMs
virsh list --all

# List networks
virsh net-list --all

# Start/stop network
virsh net-start default
virsh net-stop default

# VM operations
virsh start <vm-name>
virsh shutdown <vm-name>
virsh destroy <vm-name>  # Force stop
virsh undefine <vm-name>  # Delete VM

# Get VM info
virsh dominfo <vm-name>
virsh domifaddr <vm-name>  # Get IP address
```

### Connection URIs

- **Linux (system)**: `qemu:///system`
- **Linux (user)**: `qemu:///session`
- **macOS**: `qemu:///session`
- **WSL2**: `qemu:///system`

### Default Locations

- **VM images**: `/var/lib/libvirt/images/`
- **Network configs**: `/etc/libvirt/qemu/networks/`
- **VM configs**: `/etc/libvirt/qemu/`
- **Logs**: `/var/log/libvirt/`

---

**Ready to start?** Proceed to the next section: [Base Image Preparation](base-images.md)