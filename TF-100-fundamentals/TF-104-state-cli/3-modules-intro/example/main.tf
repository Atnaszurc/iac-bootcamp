# TF-104 Section 3: Modules Introduction
# Demonstrates: calling a local child module, module inputs/outputs
# Provider: dmacvicar/libvirt (local virtualization — no cloud credentials)
# Run: terraform init && terraform apply
#
# Structure:
#   main.tf          ← root module (this file)
#   variables.tf     ← root inputs
#   modules/vm/      ← child module (network + storage + VM)

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
# Call the local VM module
# ─────────────────────────────────────────────────────────────────────────────

module "web_vm" {
  source = "./modules/vm"

  vm_name        = "${var.project_name}-web"
  base_image_url = var.base_image_url
  ssh_public_key = var.ssh_public_key
  memory_mb      = 1024
  vcpu_count     = 1
  network_cidr   = "10.50.1.0/24"
}

module "db_vm" {
  source = "./modules/vm"

  vm_name        = "${var.project_name}-db"
  base_image_url = var.base_image_url
  ssh_public_key = var.ssh_public_key
  memory_mb      = 2048
  vcpu_count     = 2
  network_cidr   = "10.50.2.0/24"
}

# ─────────────────────────────────────────────────────────────────────────────
# Outputs from modules
# ─────────────────────────────────────────────────────────────────────────────

output "web_vm_ip" {
  description = "IP address of the web VM"
  value       = module.web_vm.ip_address
}

output "db_vm_ip" {
  description = "IP address of the database VM"
  value       = module.db_vm.ip_address
}