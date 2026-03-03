# =============================================================================
# modules/libvirt-vm/main.tf
# Reusable libvirt VM pool module for canary/blue-green deployments
# =============================================================================

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
  }
}

# ---------------------------------------------------------------------------
# Base image volume (shared read-only backing store for this pool)
# ---------------------------------------------------------------------------
resource "libvirt_volume" "base" {
  name = "${var.pool_name}-base.qcow2"
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
}

# ---------------------------------------------------------------------------
# Per-VM disk volumes (thin-provisioned clones of the base image)
# ---------------------------------------------------------------------------
resource "libvirt_volume" "vm" {
  count    = var.vm_count
  name     = "${var.pool_name}-vm-${count.index}.qcow2"
  pool     = var.storage_pool
  capacity = var.disk_size_bytes
  backing_store = {
    path = libvirt_volume.base.id
    format = {
      type = "qcow2"
    }
  }

  # Create new VMs before destroying old ones — enables zero-downtime rollout
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Cloud-init disks (one per VM)
# ---------------------------------------------------------------------------
resource "libvirt_cloudinit_disk" "vm" {
  count = var.vm_count
  name  = "${var.pool_name}-cloudinit-${count.index}.iso"

  user_data = <<-EOF
    #cloud-config
    hostname: ${var.pool_name}-${count.index}
    users:
      - name: terraform
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ${var.ssh_public_key}
    package_update: false
  EOF
  
  meta_data = yamlencode({
    instance-id    = "${var.pool_name}-${count.index}"
    local-hostname = "${var.pool_name}-${count.index}"
  })
}

# Upload cloud-init ISOs to the pool as volumes
resource "libvirt_volume" "cloudinit" {
  count = var.vm_count
  name  = "${var.pool_name}-cloudinit-${count.index}-vol"
  pool  = var.storage_pool
  create = {
    content = {
      url = libvirt_cloudinit_disk.vm[count.index].path
    }
  }
}

# ---------------------------------------------------------------------------
# VM domains
# ---------------------------------------------------------------------------
resource "libvirt_domain" "vm" {
  count  = var.vm_count
  name   = "${var.pool_name}-vm-${count.index}"
  memory = var.memory_mb
  vcpu   = var.vcpu_count
  type   = "kvm"

  devices = {
    disk = [
      {
        volume = {
          volume = libvirt_volume.vm[count.index].id
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        volume = {
          volume = libvirt_volume.cloudinit[count.index].id
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
          network = var.network_id
        }
        model = {
          type = "virtio"
        }
        wait_for_lease = false
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

  lifecycle {
    create_before_destroy = true
  }
}