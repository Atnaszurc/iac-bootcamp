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
  name = "${var.vm_name}-init.iso"
  pool = libvirt_pool.this.name
  create = {
    content = {
      url = libvirt_cloudinit_disk.init.path
    }
  }
}

resource "libvirt_domain" "this" {
  name        = var.vm_name
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
            pool   = libvirt_volume.disk.pool
            volume = libvirt_volume.disk.name
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
            network = libvirt_network.this.name
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

# Read the address DHCP handed out (wait_for_ip above guarantees there is one)
data "libvirt_domain_interface_addresses" "this" {
  domain = libvirt_domain.this.name
  source = "lease"
}
