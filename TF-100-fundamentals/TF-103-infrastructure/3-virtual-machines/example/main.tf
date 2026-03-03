# TF-103 Section 3: Virtual Machines
# Demonstrates: libvirt_domain — creating VMs with cloud-init, networking, storage
# Provider: dmacvicar/libvirt (local virtualization — no cloud credentials)
# Run: terraform init && terraform apply
#
# Prerequisites: libvirt/KVM installed and running
# See: docs/libvirt-setup.md

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
# Network for the VMs
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_network" "vm_network" {
  name      = "${var.project_name}-vm-net"
  autostart = true
  
  # Note: In 0.9.3, mode and addresses are not supported
  # Networks are automatically NAT-enabled with DHCP
}

# ─────────────────────────────────────────────────────────────────────────────
# Storage pool
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_pool" "vms" {
  name = "${var.project_name}-vms"
  type = "dir"
  target = {
    path = "/var/lib/libvirt/images/${var.project_name}-vms"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Base image (downloaded once, shared across VMs)
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_volume" "base" {
  name = "${var.project_name}-base.qcow2"
  pool = libvirt_pool.vms.name
  create = {
    content = {
      url = var.base_image_url
    }
  }
  target = {
    format = {
      type = "qcow2"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Per-VM disk (thin clone of base image)
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_volume" "vm_disk" {
  for_each = var.vms

  name     = "${var.project_name}-${each.key}.qcow2"
  pool     = libvirt_pool.vms.name
  capacity = each.value.disk_size_bytes
  backing_store = {
    path = libvirt_volume.base.id
    format = {
      type = "qcow2"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Cloud-init per VM
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_cloudinit_disk" "vm_init" {
  for_each = var.vms

  name = "${var.project_name}-${each.key}-init.iso"

  user_data = <<-EOT
    #cloud-config
    hostname: ${each.key}
    users:
      - name: terraform
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ${var.ssh_public_key}
    packages:
      - curl
  EOT
  
  meta_data = yamlencode({
    instance-id    = "${var.project_name}-${each.key}"
    local-hostname = each.key
  })
}

# Upload cloud-init ISOs to the pool as volumes
resource "libvirt_volume" "cloudinit" {
  for_each = var.vms
  
  name = "${var.project_name}-${each.key}-init-vol"
  pool = libvirt_pool.vms.name
  create = {
    content = {
      url = libvirt_cloudinit_disk.vm_init[each.key].path
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Virtual machines
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_domain" "vm" {
  for_each = var.vms

  name   = "${var.project_name}-${each.key}"
  memory = each.value.memory_mb
  vcpu   = each.value.vcpu_count
  type   = "kvm"

  devices = {
    disk = [
      {
        volume = {
          volume = libvirt_volume.vm_disk[each.key].id
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        volume = {
          volume = libvirt_volume.cloudinit[each.key].id
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
          network = libvirt_network.vm_network.name
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
          port = 0
          type = "serial"
        }
      }
    ]
  }
}