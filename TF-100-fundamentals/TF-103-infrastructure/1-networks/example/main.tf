# TF-103 Section 1: Networks
# Demonstrates: libvirt_network — NAT network with DHCP + DNS, isolated network
# Provider: dmacvicar/libvirt (local virtualization — no cloud credentials)
# Run: terraform init && terraform apply
#
# Prerequisites: libvirt/KVM installed and running
# See: docs/libvirt-setup.md

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
  prefix_length = tonumber(split("/", var.network_cidr)[1])
}

# ─────────────────────────────────────────────────────────────────────────────
# NAT network: VMs on this network can reach the internet via NAT.
# The host gets the first address; DHCP hands out .100–.200; libvirt's
# dnsmasq answers DNS for the "<network_name>.local" domain.
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_network" "main" {
  name      = "${var.network_name}-net"
  autostart = true

  forward = {
    mode = "nat"
  }

  domain = {
    name = "${var.network_name}.local"
  }

  dns = {
    enable = "yes"
  }

  ips = [
    {
      address = cidrhost(var.network_cidr, 1)
      prefix  = local.prefix_length
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

# ─────────────────────────────────────────────────────────────────────────────
# Isolated network: VMs can talk to each other and the host, but not the
# internet. An isolated network is simply one WITHOUT a forward attribute.
# No dhcp block: VMs on this network need static addresses.
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_network" "isolated" {
  name      = "${var.network_name}-isolated"
  autostart = false

  ips = [
    {
      address = cidrhost(var.isolated_cidr, 1)
      prefix  = tonumber(split("/", var.isolated_cidr)[1])
    }
  ]
}
