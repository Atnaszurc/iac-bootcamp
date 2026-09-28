# TF-203: YAML-Driven Configuration
# Demonstrates: yamldecode(), locals with for_each, YAML-driven libvirt resources
# Provider: dmacvicar/libvirt (local virtualization — no cloud credentials)
# Run: terraform init && terraform apply
#
# Pattern: Read VM definitions from a YAML file, create resources dynamically

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
# Load VM definitions from YAML
# ─────────────────────────────────────────────────────────────────────────────

locals {
  config = yamldecode(file("${path.module}/vms.yaml"))
  vms    = local.config.virtual_machines
}

# ─────────────────────────────────────────────────────────────────────────────
# Shared storage pool
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_pool" "main" {
  name = "tf203-pool"
  type = "dir"
  target = {
    path = "/var/lib/libvirt/images/tf203"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Base image (shared across all VMs)
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_volume" "base" {
  name = "tf203-base.qcow2"
  pool = libvirt_pool.main.name
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
# Per-VM network (one NAT network per VM, CIDR from YAML)
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_network" "vm" {
  for_each = { for vm in local.vms : vm.name => vm }

  name      = "${each.key}-net"
  autostart = true

  forward = {
    mode = "nat"
  }

  ips = [
    {
      address = cidrhost(each.value.network_cidr, 1)
      prefix  = tonumber(split("/", each.value.network_cidr)[1])
      dhcp = {
        ranges = [
          {
            start = cidrhost(each.value.network_cidr, 100)
            end   = cidrhost(each.value.network_cidr, 200)
          }
        ]
      }
    }
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Per-VM disk (thin clone of base)
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_volume" "vm" {
  for_each = { for vm in local.vms : vm.name => vm }

  name     = "${each.key}.qcow2"
  pool     = libvirt_pool.main.name
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
# Per-VM cloud-init
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_cloudinit_disk" "vm" {
  for_each = { for vm in local.vms : vm.name => vm }

  name = "${each.key}-init.iso"

  user_data = <<-EOT
    #cloud-config
    hostname: ${each.key}
    users:
      - name: terraform
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ${var.ssh_public_key}
    packages: ${jsonencode(each.value.packages)}
  EOT

  meta_data = yamlencode({
    instance-id    = "${each.key}-${md5(each.key)}"
    local-hostname = each.key
  })
}

# Upload cloud-init ISO to pool
resource "libvirt_volume" "cloudinit" {
  for_each = { for vm in local.vms : vm.name => vm }

  name = "${each.key}-cloudinit.iso"
  pool = libvirt_pool.main.name
  create = {
    content = {
      url = libvirt_cloudinit_disk.vm[each.key].path
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Virtual machines (defined entirely by YAML)
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_domain" "vm" {
  for_each = { for vm in local.vms : vm.name => vm }

  name        = each.key
  type        = "kvm"
  memory      = each.value.memory_mb
  memory_unit = "MiB"
  vcpu        = each.value.vcpu_count
  running     = true

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_volume.vm[each.key].pool
            volume = libvirt_volume.vm[each.key].name
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
            network = libvirt_network.vm[each.key].name
          }
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
# Outputs
# ─────────────────────────────────────────────────────────────────────────────

output "vm_names" {
  description = "Names of all created VMs"
  value       = [for vm in libvirt_domain.vm : vm.name]
}