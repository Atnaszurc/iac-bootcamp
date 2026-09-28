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
# Network for the VMs (NAT + DHCP)
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_network" "vm_network" {
  name      = "${var.project_name}-vm-net"
  autostart = true

  forward = {
    mode = "nat"
  }

  ips = [
    {
      address = cidrhost(var.network_cidr, 1)
      prefix  = tonumber(split("/", var.network_cidr)[1])
      dhcp = {
        ranges = [
          {
            start = cidrhost(var.network_cidr, 100)
            end   = cidrhost(var.network_cidr, 200)
          }
        ]
      }
    }
  ]
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
    path = libvirt_volume.base.path
    format = {
      type = "qcow2"
    }
  }
  target = {
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

  name = "${var.project_name}-${each.key}-init.iso"
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

  name        = "${var.project_name}-${each.key}"
  memory      = each.value.memory_mb
  memory_unit = "MiB" # without this, memory is interpreted as KiB
  vcpu        = each.value.vcpu_count
  type        = "kvm"
  running     = true

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  # Plural names: disks, interfaces, consoles. Terraform silently ignores
  # unknown keys inside nested attributes — a typo means a missing device.
  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_volume.vm_disk[each.key].pool
            volume = libvirt_volume.vm_disk[each.key].name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          type = "qcow2"
        }
      },
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.cloudinit[each.key].pool
            volume = libvirt_volume.cloudinit[each.key].name
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      }
    ]
    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = libvirt_network.vm_network.name
          }
        }
        wait_for_ip = {
          source  = "lease"
          timeout = 300
        }
      }
    ]
    consoles = [
      {
        target = {
          type = "serial"
          port = 0
        }
      }
    ]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# IP addresses from the DHCP leases
# ─────────────────────────────────────────────────────────────────────────────

data "libvirt_domain_interface_addresses" "vm" {
  for_each = libvirt_domain.vm

  domain = each.value.name
  source = "lease"
}

output "vm_ips" {
  description = "IP address of each VM, keyed by VM name suffix"
  value = {
    for name, d in data.libvirt_domain_interface_addresses.vm :
    name => try(d.interfaces[0].addrs[0].addr, null)
  }
}
