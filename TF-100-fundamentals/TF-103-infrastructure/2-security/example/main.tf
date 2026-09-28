# TF-103 Section 2: Security Groups (libvirt network filtering)
# Demonstrates: libvirt_network with DHCP, libvirt_domain with network filter rules
# Provider: dmacvicar/libvirt (local virtualization — no cloud credentials)
# Run: terraform init && terraform apply
#
# Prerequisites: libvirt/KVM installed and running
# See: docs/libvirt-setup.md
#
# Note: libvirt uses nwfilter (network filtering) for security rules.
# This example shows the network and storage setup that precedes VM creation.

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
# Network with explicit DHCP range (security: limit IP allocation)
# A small DHCP range caps how many guests can join; a fixed DHCP host entry
# pins the hardened VM to a known address that firewall rules can reference.
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_network" "secure" {
  name      = "${var.project_name}-secure-net"
  autostart = true

  forward = {
    mode = "nat"
  }

  ips = [
    {
      address = cidrhost(var.network_cidr, 1)
      prefix  = tonumber(split("/", var.network_cidr)[1])
      dhcp = {
        # Only 10 addresses available for dynamic leases
        ranges = [
          {
            start = cidrhost(var.network_cidr, 100)
            end   = cidrhost(var.network_cidr, 109)
          }
        ]
        # Static lease for the hardened VM
        hosts = [
          {
            name = "${var.project_name}-secure-vm"
            ip   = cidrhost(var.network_cidr, 10)
          }
        ]
      }
    }
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Storage pool for this security example
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_pool" "secure" {
  name = "${var.project_name}-secure-pool"
  type = "dir"
  target = {
    path = "/var/lib/libvirt/images/${var.project_name}-secure"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Base volume (OS image)
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_volume" "base" {
  name = "${var.project_name}-base.qcow2"
  pool = libvirt_pool.secure.name
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
# Cloud-init with security hardening
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_cloudinit_disk" "secure" {
  name = "${var.project_name}-cloudinit.iso"

  user_data = <<-EOT
    #cloud-config
    hostname: ${var.project_name}-secure-vm
    # Disable root login
    disable_root: true
    # Require SSH key authentication
    ssh_pwauth: false
    users:
      - name: terraform
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ${var.ssh_public_key}
    # Security packages
    packages:
      - ufw
      - fail2ban
    runcmd:
      - ufw default deny incoming
      - ufw default allow outgoing
      - ufw allow ssh
      - ufw --force enable
  EOT

  meta_data = yamlencode({
    instance-id    = "${var.project_name}-secure-vm"
    local-hostname = "${var.project_name}-secure-vm"
  })
}