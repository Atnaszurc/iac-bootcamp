# PKR-103 Packer Variables Example
# Demonstrates variable declaration, locals, and var-file usage
#
# Usage:
#   packer validate ubuntu.pkr.hcl
#   packer build -var-file="dev.pkrvars.hcl" ubuntu.pkr.hcl
#   packer build -var-file="prod.pkrvars.hcl" ubuntu.pkr.hcl
#   packer build -var "os_version=24.04" ubuntu.pkr.hcl

packer {
  required_version = ">= 1.14.0"
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1.0"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Variables — parameterize the template for different environments
# ─────────────────────────────────────────────────────────────────────────────
variable "os_version" {
  description = "Ubuntu LTS version to build (e.g. 22.04, 24.04)"
  type        = string
  default     = "22.04"
}

variable "disk_size" {
  description = "Disk size for the VM (e.g. 10G, 20G)"
  type        = string
  default     = "10G"
}

variable "memory_mb" {
  description = "RAM allocation in MB"
  type        = number
  default     = 2048
}

variable "cpu_count" {
  description = "Number of virtual CPUs"
  type        = number
  default     = 2
}

variable "headless" {
  description = "Run QEMU without a display window (set false for debugging)"
  type        = bool
  default     = true
}

variable "vm_name" {
  description = "Base name for the output image"
  type        = string
  default     = "ubuntu-base"
}

variable "ssh_password" {
  description = "SSH password for the build user (use PKR_VAR_ssh_password env var)"
  type        = string
  sensitive   = true
  default     = "ubuntu"
}

variable "extra_packages" {
  description = "Additional packages to install during provisioning"
  type        = list(string)
  default     = ["curl", "wget"]
}

# ─────────────────────────────────────────────────────────────────────────────
# Locals — computed values derived from variables
# ─────────────────────────────────────────────────────────────────────────────
locals {
  # Build timestamp for unique image names
  timestamp = formatdate("YYYYMMDD-HHmmss", timestamp())

  # Derived image name: ubuntu-base-22.04-20260228-143000
  image_name = "${var.vm_name}-${var.os_version}-${local.timestamp}"

  # Derived ISO URL from os_version variable
  iso_url = "https://releases.ubuntu.com/${var.os_version}/ubuntu-${var.os_version}-live-server-amd64.iso"

  # Package list as a shell command
  packages_cmd = "sudo apt-get install -y ${join(" ", var.extra_packages)}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Source block — uses variables and locals
# ─────────────────────────────────────────────────────────────────────────────
source "qemu" "ubuntu" {
  # ISO — derived from os_version variable via local
  iso_url      = local.iso_url
  iso_checksum = "sha256:9bc6028870aef3f74f4e16b900008179e78b130e6b0b9a140635434a46aa98b0"

  # VM sizing — all from variables
  disk_size = var.disk_size
  memory    = var.memory_mb
  cpus      = var.cpu_count
  headless  = var.headless

  # SSH communicator — password is sensitive
  ssh_username = "ubuntu"
  ssh_password = var.ssh_password
  ssh_timeout  = "20m"

  # Output — uses computed image name
  output_directory = "output-${var.vm_name}"
  vm_name          = "${local.image_name}.qcow2"
  format           = "qcow2"

  boot_command = [
    "<enter><wait>",
    "e<wait>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<f10>"
  ]
  http_directory = "http"
}

# ─────────────────────────────────────────────────────────────────────────────
# Build block
# ─────────────────────────────────────────────────────────────────────────────
build {
  name    = "ubuntu-parameterized"
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      local.packages_cmd,
      "echo 'Build: ${local.image_name}'"
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      image_name = local.image_name
      os_version = var.os_version
      disk_size  = var.disk_size
      memory_mb  = tostring(var.memory_mb)
      build_date = formatdate("YYYY-MM-DD", timestamp())
    }
  }
}