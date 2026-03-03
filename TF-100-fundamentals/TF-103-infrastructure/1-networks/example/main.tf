# TF-103 Section 1: Networks
# Demonstrates: libvirt_network — NAT network with DNS
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

# ─────────────────────────────────────────────────────────────────────────────
# NAT network: VMs on this network can reach the internet via NAT
# In 0.9.3, networks are automatically configured as NAT with DHCP
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_network" "main" {
  name      = "${var.network_name}-net"
  autostart = true
  
  # Note: In 0.9.3, mode, addresses, and dns blocks are not supported
  # Networks are automatically configured with NAT and DHCP
}

# ─────────────────────────────────────────────────────────────────────────────
# Isolated network: VMs can talk to each other but not the internet
# In 0.9.3, all networks are NAT-enabled by default
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_network" "isolated" {
  name      = "${var.network_name}-isolated"
  autostart = false
  
  # Note: In 0.9.3, cannot create truly isolated networks
  # This will also be NAT-enabled
}