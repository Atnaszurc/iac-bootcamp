# TF-302 Section 2: Check blocks
# A web server VM, and checks that keep an eye on it on every plan and apply.
# Provider: dmacvicar/libvirt (local virtualization — no cloud credentials)
#
#   terraform init && terraform apply
#   terraform plan          # checks run again: try it after `virsh shutdown`
#   terraform test          # mocked: no libvirt needed

terraform {
  required_version = ">= 1.14"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

locals {
  gib = 1073741824
  # Fixed address from a DHCP host entry, so checks know where to look
  vm_ip = cidrhost(var.network_cidr, 10)
}

resource "libvirt_network" "main" {
  name      = "${var.vm_name}-net"
  autostart = true
  forward   = { mode = "nat" }
  ips = [{
    address = cidrhost(var.network_cidr, 1)
    prefix  = tonumber(split("/", var.network_cidr)[1])
    dhcp = {
      ranges = [{ start = cidrhost(var.network_cidr, 100), end = cidrhost(var.network_cidr, 200) }]
      hosts  = [{ name = var.vm_name, ip = local.vm_ip }]
    }
  }]
}

resource "libvirt_pool" "main" {
  name   = "${var.vm_name}-pool"
  type   = "dir"
  target = { path = "/var/lib/libvirt/images/${var.vm_name}" }
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
  capacity = 10 * local.gib
  backing_store = {
    path   = libvirt_volume.base.path
    format = { type = "qcow2" }
  }
  target = { format = { type = "qcow2" } }
}

resource "libvirt_cloudinit_disk" "init" {
  name = "${var.vm_name}-init.iso"
  user_data = "#cloud-config\n${yamlencode({
    hostname = var.vm_name
    packages = ["nginx"]
    runcmd   = ["echo 'hello from ${var.vm_name}' > /var/www/html/index.html"]
  })}"
  meta_data = yamlencode({ instance-id = var.vm_name, local-hostname = var.vm_name })
}

resource "libvirt_volume" "cloudinit" {
  name = "${var.vm_name}-init.iso"
  pool = libvirt_pool.main.name
  create = {
    content = { url = libvirt_cloudinit_disk.init.path }
  }
}

resource "libvirt_domain" "web" {
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
}

# ─────────────────────────────────────────────────────────────────────────────
# Checks: they WARN instead of failing, and run on every plan and apply
# ─────────────────────────────────────────────────────────────────────────────

# 1. Is the website answering on the reserved address? A data source
#    declared inside a check is "scoped": if it fails (VM still booting,
#    nginx not installed yet), you get a warning instead of a failed plan.
check "web_health" {
  data "http" "home" {
    url = "http://${local.vm_ip}/"
    retry { attempts = 2 }
    depends_on = [libvirt_domain.web]
  }

  assert {
    condition     = data.http.home.status_code == 200
    error_message = "http://${local.vm_ip}/ returned ${data.http.home.status_code}, expected 200."
  }

  assert {
    condition     = strcontains(data.http.home.response_body, var.vm_name)
    error_message = "The page doesn't mention ${var.vm_name}: is this the right server?"
  }
}

# 2. Is there room left on the host for the next VM?
data "libvirt_node_info" "host" {}

check "host_memory_headroom" {
  assert {
    condition     = data.libvirt_node_info.host.memory_total_kb / 1024 - var.memory_mb >= var.min_host_headroom_mb
    error_message = "After this VM, the host has less than ${var.min_host_headroom_mb} MiB left for other VMs."
  }
}

output "url" {
  value = "http://${local.vm_ip}/"
}
