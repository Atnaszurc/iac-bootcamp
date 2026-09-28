# =============================================================================
# modules/libvirt-vm/main.tf
# One deployment pool: N identical web VMs built from one base image.
#
# Every VM name contains a "generation" suffix. A new generation starts when
# anything that shapes the VM changes (image, size, web page). The new VMs get
# new names, so create_before_destroy can build them next to the old ones.
# With fixed names, libvirt would refuse: two domains can't share a name.
# =============================================================================

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

locals {
  user_data = [
    for i in range(var.vm_count) : <<-EOF
      #cloud-config
      hostname: ${var.pool_name}-vm-${i}
      users:
        - name: terraform
          sudo: ALL=(ALL) NOPASSWD:ALL
          shell: /bin/bash
          ssh_authorized_keys:
            - ${var.ssh_public_key}
      packages:
        - nginx
      runcmd:
        - . /etc/os-release && echo "pool=${var.pool_name} vm=${i} os=$PRETTY_NAME" > /var/www/html/index.html
    EOF
  ]
}

# ---------------------------------------------------------------------------
# Generation: changes whenever a keeper changes, and forces replacement of
# everything below through replace_triggered_by.
# Scaling (vm_count) is NOT a keeper, so adding a VM doesn't roll the pool.
# ---------------------------------------------------------------------------
resource "random_id" "generation" {
  byte_length = 2

  keepers = {
    base_image_url = var.base_image_url
    memory_mb      = var.memory_mb
    vcpu_count     = var.vcpu_count
  }
}

locals {
  prefix = "${var.pool_name}-${random_id.generation.hex}"
}

# ---------------------------------------------------------------------------
# Base image volume (shared backing store for this generation)
# ---------------------------------------------------------------------------
resource "libvirt_volume" "base" {
  name = "${local.prefix}-base.qcow2"
  pool = var.storage_pool
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

  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [random_id.generation]
  }
}

# ---------------------------------------------------------------------------
# Per-VM disk (thin clone of the base image)
# ---------------------------------------------------------------------------
resource "libvirt_volume" "vm" {
  count    = var.vm_count
  name     = "${local.prefix}-vm-${count.index}.qcow2"
  pool     = var.storage_pool
  capacity = var.disk_size_bytes
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

  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [random_id.generation]
  }
}

# ---------------------------------------------------------------------------
# Cloud-init: installs nginx and writes a page saying which pool/OS answered
# ---------------------------------------------------------------------------
resource "libvirt_cloudinit_disk" "vm" {
  count = var.vm_count
  name  = "${local.prefix}-vm-${count.index}-init.iso"

  user_data = local.user_data[count.index]
  meta_data = yamlencode({
    instance-id    = "${local.prefix}-vm-${count.index}"
    local-hostname = "${var.pool_name}-vm-${count.index}"
  })
}

resource "libvirt_volume" "cloudinit" {
  count = var.vm_count
  name  = "${local.prefix}-vm-${count.index}-init.iso"
  pool  = var.storage_pool
  create = {
    content = {
      url = libvirt_cloudinit_disk.vm[count.index].path
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# VM domains
# ---------------------------------------------------------------------------
resource "libvirt_domain" "vm" {
  count       = var.vm_count
  name        = "${local.prefix}-vm-${count.index}"
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
            pool   = libvirt_volume.vm[count.index].pool
            volume = libvirt_volume.vm[count.index].name
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
            pool   = libvirt_volume.cloudinit[count.index].pool
            volume = libvirt_volume.cloudinit[count.index].name
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
            network = var.network_name
          }
        }
        # The apply waits for an address, so the new generation is up before
        # the old one is destroyed.
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

  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [random_id.generation]
  }
}

data "libvirt_domain_interface_addresses" "vm" {
  count = var.vm_count

  domain = libvirt_domain.vm[count.index].name
  source = "lease"
}
