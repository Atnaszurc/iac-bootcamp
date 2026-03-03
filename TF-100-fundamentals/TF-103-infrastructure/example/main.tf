# TF-103: Infrastructure Resources — Complete Example
# Demonstrates: libvirt network, storage pool, volume, and domain (VM)
# Provider: dmacvicar/libvirt (local virtualization — no cloud credentials)
# Run: terraform init && terraform apply
#
# Prerequisites: libvirt/KVM installed and running
# See: docs/libvirt-setup.md
# Updated for libvirt provider 0.9.x

terraform {
  required_version = ">= 1.14"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# ─────────────────────────────────────────────────────────────────────────────
# Network: isolated virtual network for the VMs
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_network" "example" {
  name      = "${var.project_name}-network"
  autostart = true
  # Note: In 0.9.x, mode and addresses are simplified
  # The network is automatically configured as NAT with DHCP
}

# ─────────────────────────────────────────────────────────────────────────────
# Storage: pool and base volume
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_pool" "example" {
  name = "${var.project_name}-pool"
  type = "dir"
  
  # In 0.9.3, target is a nested attribute (not a block)
  target = {
    path = "/var/lib/libvirt/images/${var.project_name}"
  }
}

resource "libvirt_volume" "base" {
  name = "${var.project_name}-base.qcow2"
  pool = libvirt_pool.example.name
  
  # In 0.9.3, use create.content.url instead of source_url
  create = {
    content = {
      url = var.base_image_url
    }
  }
}

resource "libvirt_volume" "vm_disk" {
  name = "${var.project_name}-disk.qcow2"
  pool = libvirt_pool.example.name
  
  # In 0.9.3, use backing_store instead of base_volume_name
  backing_store = {
    path = libvirt_volume.base.path
    format = {
      type = "qcow2"
    }
  }
  
  capacity = var.disk_size_bytes
}

# ─────────────────────────────────────────────────────────────────────────────
# Cloud-init: user data for the VM
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_cloudinit_disk" "example" {
  name = "${var.project_name}-cloudinit.iso"

  user_data = <<-EOT
    #cloud-config
    hostname: ${var.project_name}-vm
    users:
      - name: terraform
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ${var.ssh_public_key}
    package_update: true
    packages:
      - curl
      - git
  EOT

  # meta_data is required in 0.9.x
  meta_data = <<-EOT
    instance-id: ${var.project_name}-vm
    local-hostname: ${var.project_name}-vm
  EOT
}

# ─────────────────────────────────────────────────────────────────────────────
# Domain (VM): the virtual machine itself
# ─────────────────────────────────────────────────────────────────────────────

# Cloud-init volume (upload ISO to libvirt volume)
resource "libvirt_volume" "cloudinit" {
  name = "${var.project_name}-cloudinit-vol"
  pool = libvirt_pool.example.name
  
  create = {
    content = {
      url = libvirt_cloudinit_disk.example.path
    }
  }
}

resource "libvirt_domain" "example" {
  name   = "${var.project_name}-vm"
  memory = var.memory_mb
  vcpu   = var.vcpu_count
  type   = "kvm"

  # In 0.9.3, all devices go in the devices nested attribute
  devices = {
    disk = [
      {
        volume = {
          volume = libvirt_volume.vm_disk.id
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        volume = {
          volume = libvirt_volume.cloudinit.id
        }
        target = {
          dev = "vdb"
          bus = "virtio"
        }
      }
    ]
    
    interface = [
      {
        network = {
          network = libvirt_network.example.name
        }
        model = {
          type = "virtio"
        }
        wait_for_lease = true
      }
    ]
    
    console = [
      {
        type = "pty"
        target = {
          type = "serial"
          port = "0"
        }
      }
    ]
    
    graphics = [
      {
        type = "spice"
        listen = {
          type = "address"
        }
      }
    ]
  }
  
  # OS configuration - removed for 0.9.3 compatibility
  # The provider will use defaults
}