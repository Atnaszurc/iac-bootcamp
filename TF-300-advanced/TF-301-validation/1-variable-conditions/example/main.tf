# TF-301 Section 1: Variable conditions
# A small libvirt setup whose inputs are all validated (see variables.tf).
# Provider: dmacvicar/libvirt (local virtualization — no cloud credentials)
#
#   terraform init
#   terraform plan -var vm_name=Web_01 -var 'ssh_public_key=...'   # fails validation
#   terraform test                                                  # runs the validation tests

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
  # ufw commands generated from the validated firewall rules
  ufw_rules = [
    for r in var.firewall_rules :
    r.from == "any" ? "ufw allow ${r.port}/${r.protocol}" : "ufw allow from ${r.from} to any port ${r.port} proto ${r.protocol}"
  ]
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
    content = { url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img" }
  }
  target = { format = { type = "qcow2" } }
}

resource "libvirt_volume" "disk" {
  count    = var.vm_count
  name     = "${var.vm_name}-${count.index}.qcow2"
  pool     = libvirt_pool.main.name
  capacity = 10737418240
  backing_store = {
    path   = libvirt_volume.base.path
    format = { type = "qcow2" }
  }
  target = { format = { type = "qcow2" } }
}

resource "libvirt_cloudinit_disk" "init" {
  count = var.vm_count
  name  = "${var.vm_name}-${count.index}-init.iso"

  # Building the YAML with yamlencode() instead of a heredoc template means
  # lists like runcmd can't end up with broken indentation.
  user_data = "#cloud-config\n${yamlencode({
    hostname = "${var.vm_name}-${count.index}"
    users = [{
      name                = "terraform"
      sudo                = "ALL=(ALL) NOPASSWD:ALL"
      shell               = "/bin/bash"
      ssh_authorized_keys = [var.ssh_public_key]
    }]
    packages = ["ufw"]
    runcmd   = concat(["ufw default deny incoming"], local.ufw_rules, ["ufw --force enable"])
  })}"

  meta_data = yamlencode({
    instance-id    = "${var.vm_name}-${count.index}"
    local-hostname = "${var.vm_name}-${count.index}"
  })
}

resource "libvirt_volume" "cloudinit" {
  count = var.vm_count
  name  = "${var.vm_name}-${count.index}-init.iso"
  pool  = libvirt_pool.main.name
  create = {
    content = { url = libvirt_cloudinit_disk.init[count.index].path }
  }
}

resource "libvirt_domain" "vm" {
  count       = var.vm_count
  name        = "${var.vm_name}-${count.index}"
  memory      = var.memory_mb
  memory_unit = "MiB"
  vcpu        = 1
  type        = "kvm"
  running     = true

  os = { type = "hvm", type_arch = "x86_64", type_machine = "q35" }

  devices = {
    disks = [
      {
        source = { volume = { pool = libvirt_volume.disk[count.index].pool, volume = libvirt_volume.disk[count.index].name } }
        target = { dev = "vda", bus = "virtio" }
        driver = { type = "qcow2" }
      },
      {
        device = "cdrom"
        source = { volume = { pool = libvirt_volume.cloudinit[count.index].pool, volume = libvirt_volume.cloudinit[count.index].name } }
        target = { dev = "sda", bus = "sata" }
      }
    ]
    interfaces = [
      {
        model       = { type = "virtio" }
        source      = { network = { network = libvirt_network.main.name } }
        wait_for_ip = { source = "lease" }
      }
    ]
  }
}

output "ufw_rules" {
  description = "Firewall commands cloud-init will run"
  value       = local.ufw_rules
}
