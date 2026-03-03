# TF-202: Canary / Blue-Green Deployments with libvirt
# Demonstrates: for_each over map(object), canary rollout pattern,
#               create_before_destroy lifecycle, module composition
# Provider: dmacvicar/libvirt (local virtualization — no cloud credentials)
# Run: terraform init && terraform apply
#
# Pattern:
#   - Each entry in var.vm_pools creates one VM pool (stable, canary, etc.)
#   - Add a new pool entry  → canary VM spins up alongside stable
#   - Remove the old entry  → stable VM is destroyed (blue-green cutover)
#   - create_before_destroy → new VM exists before old is removed

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
# Shared storage pool (all VM pools share one storage pool)
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_pool" "shared" {
  name = "canary-pool"
  type = "dir"
  target = {
    path = "/var/lib/libvirt/images/canary"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Shared network (all VM pools share one NAT network)
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_network" "shared" {
  name      = "canary-net"
  autostart = true
  
  # Note: In 0.9.3, mode and addresses are not supported
}

# ─────────────────────────────────────────────────────────────────────────────
# Call the VM pool module for each entry in var.vm_pools
# Each pool entry = one deployment slot (stable, canary, v2, etc.)
# ─────────────────────────────────────────────────────────────────────────────

module "vm_pool" {
  source   = "./modules/libvirt-vm/"
  for_each = var.vm_pools

  pool_name      = each.key
  base_image_url = each.value.base_image_url
  memory_mb      = each.value.memory_mb
  vcpu_count     = each.value.vcpu_count
  vm_count       = each.value.vm_count
  ssh_public_key = var.ssh_public_key
  storage_pool   = libvirt_pool.shared.name
  network_id     = libvirt_network.shared.name
}

# ─────────────────────────────────────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────────────────────────────────────

output "vm_pools" {
  description = "Map of pool names to their VM names"
  value       = { for k, v in module.vm_pool : k => v.vm_names }
}

output "active_pools" {
  description = "Names of all active deployment pools"
  value       = keys(module.vm_pool)
}
