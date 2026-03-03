# Child module: vm
# Creates a complete VM: network, storage pool, volume, cloud-init, domain
# Called from the root module (../../main.tf)

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
  }
}

resource "libvirt_network" "this" {
  name      = "${var.vm_name}-net"
  autostart = true
  
  # Note: In 0.9.3, mode and addresses are not supported
  # Networks are automatically NAT-enabled with DHCP
}

resource "libvirt_pool" "this" {
  name = "${var.vm_name}-pool"
  type = "dir"
  target = {
    path = "/var/lib/libvirt/images/${var.vm_name}"
  }
}

resource "libvirt_volume" "base" {
  name = "${var.vm_name}-base.qcow2"
  pool = libvirt_pool.this.name
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

resource "libvirt_volume" "disk" {
  name     = "${var.vm_name}.qcow2"
  pool     = libvirt_pool.this.name
  capacity = var.disk_size_bytes
  backing_store = {
    path = libvirt_volume.base.id
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_cloudinit_disk" "init" {
  name = "${var.vm_name}-init.iso"

  user_data = <<-EOT
    #cloud-config
    hostname: ${var.vm_name}
    users:
      - name: terraform
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ${var.ssh_public_key}
  EOT
  
  meta_data = yamlencode({
    instance-id    = var.vm_name
    local-hostname = var.vm_name
  })
}

# Upload cloud-init ISO to the pool as a volume
resource "libvirt_volume" "cloudinit" {
  name = "${var.vm_name}-init-vol"
  pool = libvirt_pool.this.name
  create = {
    content = {
      url = libvirt_cloudinit_disk.init.path
    }
  }
}

resource "libvirt_domain" "this" {
  name   = var.vm_name
  memory = var.memory_mb
  vcpu   = var.vcpu_count
  type   = "kvm"

  devices = {
    disk = [
      {
        volume = {
          volume = libvirt_volume.disk.id
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
          network = libvirt_network.this.name
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