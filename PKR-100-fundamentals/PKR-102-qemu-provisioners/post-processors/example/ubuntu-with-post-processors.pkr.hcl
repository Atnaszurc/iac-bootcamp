# PKR-102 Post-Processors Example
# Demonstrates shell-local and manifest post-processors
#
# NOTE: This template requires a real Ubuntu ISO and QEMU to execute.
# It is provided as a reference for the post-processor syntax and patterns.
# The post-processor blocks at the bottom are the focus of this example.

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
# Variables
# ─────────────────────────────────────────────────────────────────────────────
variable "os_version" {
  description = "Ubuntu version to build"
  type        = string
  default     = "22.04"
}

variable "output_directory" {
  description = "Directory for the output image"
  type        = string
  default     = "output-ubuntu"
}

# ─────────────────────────────────────────────────────────────────────────────
# Source: QEMU builder
# ─────────────────────────────────────────────────────────────────────────────
source "qemu" "ubuntu" {
  # ISO configuration
  iso_url      = "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"
  iso_checksum = "sha256:9bc6028870aef3f74f4e16b900008179e78b130e6b0b9a140635434a46aa98b0"

  # VM configuration
  disk_size = "10G"
  memory    = 2048
  cpus      = 2
  headless  = true

  # SSH communicator
  ssh_username = "ubuntu"
  ssh_password = "ubuntu"
  ssh_timeout  = "20m"

  # Output
  output_directory = var.output_directory
  vm_name          = "ubuntu-${var.os_version}.qcow2"
  format           = "qcow2"

  # Boot configuration for automated install
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
  name    = "ubuntu-base"
  sources = ["source.qemu.ubuntu"]

  # Provisioner: runs INSIDE the VM
  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y curl wget",
      "echo 'Provisioning complete'"
    ]
  }

  # ─────────────────────────────────────────────────────────────────────────
  # Post-Processor 1: shell-local
  # Runs on the BUILD MACHINE after the image is exported
  # Use case: log the build, compress the image, move to storage
  # ─────────────────────────────────────────────────────────────────────────
  post-processor "shell-local" {
    inline = [
      "echo '=== Post-Processing ==='",
      "echo 'Build completed at: '$(date)",
      "echo 'Output directory: ${var.output_directory}'",
      "ls -lh ${var.output_directory}/ 2>/dev/null || echo 'Output directory not found (expected in dry-run)'"
    ]
  }

  # ─────────────────────────────────────────────────────────────────────────
  # Post-Processor 2: manifest
  # Records build metadata to a JSON file
  # Use case: CI/CD pipelines, build auditing, image catalogs
  # ─────────────────────────────────────────────────────────────────────────
  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true

    # Custom metadata embedded in the manifest
    custom_data = {
      os_version   = var.os_version
      build_date   = formatdate("YYYY-MM-DD", timestamp())
      build_time   = formatdate("HH:mm:ss", timestamp())
      builder_type = "qemu"
      description  = "Ubuntu base image with curl and wget"
    }
  }
}