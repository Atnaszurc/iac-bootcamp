# TF-104: State Management & CLI
# Demonstrates: terraform state, CLI commands, outputs — using libvirt
# Provider: dmacvicar/libvirt (local virtualization — no cloud credentials)
# Run: terraform init && terraform plan && terraform apply
#
# Key CLI commands to practice:
#   terraform init        - Initialize working directory
#   terraform validate    - Validate configuration
#   terraform fmt         - Format code
#   terraform plan        - Preview changes
#   terraform apply       - Apply changes
#   terraform show        - Show current state
#   terraform state list  - List resources in state
#   terraform output      - Show outputs
#   terraform destroy     - Destroy infrastructure

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
# Network
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_network" "main" {
  name      = "${var.project_name}-net"
  autostart = true

  forward = {
    mode = "nat"
  }

  ips = [
    {
      address = "10.104.0.1"
      prefix  = 24
      dhcp = {
        ranges = [{ start = "10.104.0.100", end = "10.104.0.200" }]
      }
    }
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Storage
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_pool" "main" {
  name = "${var.project_name}-pool"
  type = "dir"
  target = {
    path = "/var/lib/libvirt/images/${var.project_name}"
  }
}

resource "libvirt_volume" "base" {
  name = "${var.project_name}-base.qcow2"
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

resource "libvirt_volume" "vm" {
  name     = "${var.project_name}-vm.qcow2"
  pool     = libvirt_pool.main.name
  capacity = 10737418240 # 10 GB
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
# Cloud-init
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_cloudinit_disk" "init" {
  name = "${var.project_name}-init.iso"

  user_data = <<-EOT
    #cloud-config
    hostname: ${var.project_name}
    users:
      - name: terraform
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ${var.ssh_public_key}
  EOT

  meta_data = yamlencode({
    instance-id    = var.project_name
    local-hostname = var.project_name
  })
}

# Upload cloud-init ISO to the pool as a volume
resource "libvirt_volume" "cloudinit" {
  name = "${var.project_name}-init-vol"
  pool = libvirt_pool.main.name
  create = {
    content = {
      url = libvirt_cloudinit_disk.init.path
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Virtual machine
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_domain" "vm" {
  name        = var.project_name
  memory      = var.memory_mb
  memory_unit = "MiB"
  vcpu        = var.vcpu_count
  type        = "kvm"
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
            pool   = libvirt_volume.vm.pool
            volume = libvirt_volume.vm.name
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
            network = libvirt_network.main.name
          }
        }
        wait_for_ip = {
          source = "lease"
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