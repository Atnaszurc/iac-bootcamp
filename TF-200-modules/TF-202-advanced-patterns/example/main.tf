# TF-202: Advanced Module Patterns
# Demonstrates: calling a local libvirt module, module composition
# Provider: dmacvicar/libvirt (local virtualization — no cloud credentials)
# Run: terraform init && terraform apply
#
# Pattern: Root module calls ./modules/libvirt/ child module
# This demonstrates the same module composition pattern as cloud providers,
# but using local libvirt resources.

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

module "vm" {
  source = "./modules/libvirt/"

  vm_name        = var.vm_name
  base_image_url = var.base_image_url
  ssh_public_key = var.ssh_public_key
  memory_mb      = var.memory_mb
  vcpu_count     = var.vcpu_count
}

output "vm_ip" {
  description = "IP address of the VM"
  value       = module.vm.ip_address
}
