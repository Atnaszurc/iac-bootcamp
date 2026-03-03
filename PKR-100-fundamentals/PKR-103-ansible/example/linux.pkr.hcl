# =============================================================================
# PKR-103: Ansible Configuration Management — Linux (Ubuntu 22.04)
# Demonstrates: qemu builder + ansible provisioner
# Builder: hashicorp/qemu (local QEMU/KVM — no cloud credentials required)
# Run: packer init . && packer build linux.pkr.hcl
# =============================================================================

packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------

variable "image_name" {
  description = "Output image name (without extension)"
  type        = string
  default     = "ubuntu-22-04-ansible"
}

variable "output_dir" {
  description = "Directory where the finished image will be written"
  type        = string
  default     = "output-ubuntu-ansible"
}

variable "ssh_username" {
  description = "SSH username for the build VM"
  type        = string
  default     = "ubuntu"
}

variable "ssh_password" {
  description = "SSH password for the build VM (used during build only)"
  type        = string
  default     = "packer"
  sensitive   = true
}

variable "memory_mb" {
  description = "RAM for the build VM (MiB)"
  type        = number
  default     = 2048
}

variable "cpus" {
  description = "vCPUs for the build VM"
  type        = number
  default     = 2
}

# ---------------------------------------------------------------------------
# Source: QEMU builder for Ubuntu 22.04
# ---------------------------------------------------------------------------

source "qemu" "ubuntu_22_04" {
  # Base ISO — Ubuntu 22.04 LTS server
  iso_url      = "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"
  iso_checksum = "sha256:9bc6028870aef3f74f4e16b900008179e78b130e6b0b9a140635434a46aa98b0"

  # Output
  output_directory = var.output_dir
  vm_name          = "${var.image_name}.qcow2"
  disk_image       = false
  format           = "qcow2"

  # VM resources
  memory    = var.memory_mb
  cpus      = var.cpus
  disk_size = "10G"

  # Accelerator
  accelerator = "kvm"

  # Network
  net_device = "virtio-net"

  # SSH communicator
  communicator     = "ssh"
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_timeout      = "20m"
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"

  # Boot configuration — autoinstall via kernel parameters
  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "linux /casper/vmlinuz --- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  # Serve cloud-init autoinstall config via HTTP
  http_directory = "http"
}

# ---------------------------------------------------------------------------
# Build: Ansible provisioner
# ---------------------------------------------------------------------------

build {
  name    = "ubuntu-22-04-ansible"
  sources = ["source.qemu.ubuntu_22_04"]

  # Step 1: Wait for cloud-init, install Ansible dependencies
  provisioner "shell" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo apt-get update -y",
      "sudo apt-get install -y python3 python3-pip"
    ]
  }

  # Step 2: Ansible provisioner — run a playbook against the build VM
  provisioner "ansible" {
    playbook_file = "ansible/site.yml"
    user          = var.ssh_username
    extra_arguments = [
      "--extra-vars", "ansible_become_pass=${var.ssh_password}",
      "--become"
    ]
  }

  # Step 3: Cleanup — generalise the image
  provisioner "shell" {
    inline = [
      "sudo cloud-init clean --logs",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo sync"
    ]
  }

  # Post-processor: record the manifest
  post-processor "manifest" {
    output     = "${var.output_dir}/manifest.json"
    strip_path = true
  }
}