# TF-103: Infrastructure Resources — Complete Example
# Demonstrates: libvirt network, storage pool, volume, and domain (VM)
# Provider: dmacvicar/libvirt (local virtualization — no cloud credentials)
# Run: terraform init && terraform apply
#
# Prerequisites: libvirt/KVM installed and running
# See: docs/libvirt-setup.md
# Written for libvirt provider 0.9.x — most settings are nested attributes
# (name = { ... }), not blocks.

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
# Network: NAT network with DHCP for the VMs
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_network" "example" {
  name      = "${var.project_name}-network"
  autostart = true

  # NAT: VMs reach the internet through the host. Omit forward for an
  # isolated network.
  forward = {
    mode = "nat"
  }

  ips = [
    {
      address = cidrhost(var.network_cidr, 1) # host side of the network
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
# Storage: pool and base volume
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_pool" "example" {
  name = "${var.project_name}-pool"
  type = "dir"

  # target is a nested attribute (target = { ... }), not a block
  target = {
    path = "/var/lib/libvirt/images/${var.project_name}"
  }
}

resource "libvirt_volume" "base" {
  name = "${var.project_name}-base.qcow2"
  pool = libvirt_pool.example.name

  # Download the cloud image into the pool
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

resource "libvirt_volume" "vm_disk" {
  name = "${var.project_name}-disk.qcow2"
  pool = libvirt_pool.example.name

  # Copy-on-write clone: only changes are written to this volume
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

  # meta_data is required
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
  name        = "${var.project_name}-vm"
  memory      = var.memory_mb
  memory_unit = "MiB" # without this, memory is interpreted as KiB
  vcpu        = var.vcpu_count
  type        = "kvm"
  running     = true # default is false: the VM would be defined but not started

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  # All devices live in the devices nested attribute. Note the PLURAL names
  # (disks, interfaces, consoles): Terraform silently ignores unknown keys
  # inside nested attributes, so a typo here produces a VM without that device.
  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_volume.vm_disk.pool
            volume = libvirt_volume.vm_disk.name
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
        # cloud-init reads its config from this CD-ROM on first boot
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.cloudinit.pool
            volume = libvirt_volume.cloudinit.name
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
            network = libvirt_network.example.name
          }
        }
        # Block the apply until DHCP has handed out an address
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

    graphics = [
      {
        vnc = {
          auto_port = true
          listen    = "127.0.0.1"
        }
      }
    ]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# IP address: read from the network's DHCP leases
# ─────────────────────────────────────────────────────────────────────────────

data "libvirt_domain_interface_addresses" "example" {
  domain = libvirt_domain.example.name
  source = "lease"
}

output "vm_ip" {
  description = "IP address assigned to the VM by DHCP"
  value       = try(data.libvirt_domain_interface_addresses.example.interfaces[0].addrs[0].addr, null)
}