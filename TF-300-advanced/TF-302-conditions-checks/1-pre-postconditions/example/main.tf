# TF-302 Section 1: Preconditions and postconditions
# A libvirt VM where every resource guards an assumption.
# Provider: dmacvicar/libvirt (local virtualization — no cloud credentials)
#
#   terraform init && terraform apply
#   terraform test          # mocked: tests both passing and failing conditions

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

locals {
  gib = 1073741824

  # Two CIDR blocks overlap if they have the same network address at the
  # shorter of the two prefix lengths.
  overlapping_reserved = [
    for r in var.reserved_cidrs : r
    if cidrhost(
      "${split("/", var.network_cidr)[0]}/${min(tonumber(split("/", var.network_cidr)[1]), tonumber(split("/", r)[1]))}", 0
      ) == cidrhost(
      "${split("/", r)[0]}/${min(tonumber(split("/", var.network_cidr)[1]), tonumber(split("/", r)[1]))}", 0
    )
  ]
}

# Facts about the host, used by preconditions below
data "libvirt_node_info" "host" {}

resource "libvirt_network" "main" {
  name      = "${var.vm_name}-net"
  autostart = true
  forward   = { mode = "nat" }
  ips = [{
    address = cidrhost(var.network_cidr, 1)
    prefix  = tonumber(split("/", var.network_cidr)[1])
    dhcp = {
      ranges = [{ start = cidrhost(var.network_cidr, 100), end = cidrhost(var.network_cidr, 200) }]
    }
  }]

  lifecycle {
    # Checked during plan: libvirt refuses to start overlapping networks,
    # but only tells you at apply time, with a much less helpful message.
    precondition {
      condition     = length(local.overlapping_reserved) == 0
      error_message = "network_cidr ${var.network_cidr} overlaps ${join(", ", local.overlapping_reserved)}. Pick another range."
    }
  }
}

resource "libvirt_pool" "main" {
  name   = "${var.vm_name}-pool"
  type   = "dir"
  target = { path = "/var/lib/libvirt/images/${var.vm_name}" }

  lifecycle {
    # Checked after apply: free space is only known once the pool exists
    postcondition {
      condition     = self.available >= var.min_free_gib * local.gib
      error_message = "Pool ${self.name} has only ${floor(self.available / local.gib)} GiB free; need at least ${var.min_free_gib} GiB."
    }
  }
}

resource "libvirt_volume" "base" {
  name = "${var.vm_name}-base.qcow2"
  pool = libvirt_pool.main.name
  create = {
    content = { url = var.base_image_url }
  }
  target = { format = { type = "qcow2" } }
}

resource "libvirt_volume" "disk" {
  name     = "${var.vm_name}.qcow2"
  pool     = libvirt_pool.main.name
  capacity = var.disk_gib * local.gib
  backing_store = {
    path   = libvirt_volume.base.path
    format = { type = "qcow2" }
  }
  target = { format = { type = "qcow2" } }

  lifecycle {
    # The image's virtual size is only known after it has been downloaded.
    # A disk smaller than its backing image won't boot properly.
    precondition {
      condition     = var.disk_gib * local.gib >= libvirt_volume.base.capacity
      error_message = "disk_gib (${var.disk_gib}) is smaller than the base image (${ceil(libvirt_volume.base.capacity / local.gib)} GiB)."
    }
  }
}

# A minimal cloud-init disk. Without one, the Ubuntu cloud image spends
# minutes looking for a datasource before it brings up networking.
resource "libvirt_cloudinit_disk" "init" {
  name      = "${var.vm_name}-init.iso"
  user_data = "#cloud-config\n${yamlencode({ hostname = var.vm_name })}"
  meta_data = yamlencode({ instance-id = var.vm_name, local-hostname = var.vm_name })
}

resource "libvirt_volume" "cloudinit" {
  name = "${var.vm_name}-init.iso"
  pool = libvirt_pool.main.name
  create = {
    content = { url = libvirt_cloudinit_disk.init.path }
  }
}

resource "libvirt_domain" "vm" {
  name        = var.vm_name
  memory      = var.memory_mb
  memory_unit = "MiB"
  vcpu        = 1
  type        = "kvm"
  running     = true

  os = { type = "hvm", type_arch = "x86_64", type_machine = "q35" }

  devices = {
    disks = [
      {
        source = { volume = { pool = libvirt_volume.disk.pool, volume = libvirt_volume.disk.name } }
        target = { dev = "vda", bus = "virtio" }
        driver = { type = "qcow2" }
      },
      {
        device = "cdrom"
        source = { volume = { pool = libvirt_volume.cloudinit.pool, volume = libvirt_volume.cloudinit.name } }
        target = { dev = "sda", bus = "sata" }
      }
    ]
    interfaces = [{
      model       = { type = "virtio" }
      source      = { network = { network = libvirt_network.main.name } }
      wait_for_ip = { source = "lease" }
    }]
  }

  lifecycle {
    # A precondition can use data sources: here, the real host's memory
    precondition {
      condition     = var.memory_mb * 1024 <= data.libvirt_node_info.host.memory_total_kb / 2
      error_message = "memory_mb (${var.memory_mb}) is more than half of this host's ${floor(data.libvirt_node_info.host.memory_total_kb / 1024)} MiB."
    }

    postcondition {
      condition     = self.running
      error_message = "VM ${self.name} was created but isn't running."
    }

    # Guards against a misspelled key inside devices, which Terraform
    # silently ignores (e.g. "interface" instead of "interfaces")
    postcondition {
      condition     = length(coalesce(self.devices.interfaces, [])) > 0
      error_message = "VM ${self.name} has no network interface."
    }
  }
}

# Data sources can have postconditions too
data "libvirt_domain_interface_addresses" "vm" {
  domain = libvirt_domain.vm.name
  source = "lease"

  lifecycle {
    postcondition {
      condition = anytrue([
        for i in self.interfaces : anytrue([
          for a in i.addrs : a.type == "ipv4" && cidrhost("${a.addr}/${split("/", var.network_cidr)[1]}", 0) == cidrhost(var.network_cidr, 0)
        ])
      ])
      error_message = "${libvirt_domain.vm.name} has no IPv4 address inside ${var.network_cidr}."
    }
  }
}

output "vm_ip" {
  value = [for a in data.libvirt_domain_interface_addresses.vm.interfaces[0].addrs : a.addr if a.type == "ipv4"][0]
}
