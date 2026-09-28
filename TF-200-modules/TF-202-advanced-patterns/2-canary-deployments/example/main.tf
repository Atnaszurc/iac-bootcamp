# =============================================================================
# TF-202 Section 2: Canary and blue-green deployments with libvirt
#
# Each entry in var.vm_pools is a deployment pool: a set of identical web VMs.
#   - Add a pool       -> new VMs next to the old ones (green next to blue)
#   - Change weights   -> shift traffic between pools (canary 10%, then 50%...)
#   - Remove a pool    -> retire it (cutover complete)
#
# libvirt has no load balancer resource, so Terraform writes an HAProxy config
# (out/haproxy.cfg) with every VM and its pool's weight. Run HAProxy on the
# host to get a real traffic split; see the README.
#
# Run: terraform init && terraform apply
# =============================================================================

terraform {
  required_version = ">= 1.14"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# ─────────────────────────────────────────────────────────────────────────────
# Shared storage pool and network (all deployment pools use them)
# ─────────────────────────────────────────────────────────────────────────────

resource "libvirt_pool" "shared" {
  name = "${var.project_name}-pool"
  type = "dir"
  target = {
    path = "/var/lib/libvirt/images/${var.project_name}"
  }
}

resource "libvirt_network" "shared" {
  name      = "${var.project_name}-net"
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

# ─────────────────────────────────────────────────────────────────────────────
# One module instance per deployment pool
# ─────────────────────────────────────────────────────────────────────────────

module "vm_pool" {
  source   = "./modules/libvirt-vm"
  for_each = var.vm_pools

  pool_name      = each.key
  base_image_url = each.value.base_image_url
  memory_mb      = each.value.memory_mb
  vcpu_count     = each.value.vcpu_count
  vm_count       = each.value.vm_count
  ssh_public_key = var.ssh_public_key
  storage_pool   = libvirt_pool.shared.name
  network_name   = libvirt_network.shared.name
}

# ─────────────────────────────────────────────────────────────────────────────
# Load balancer config: every VM of every pool, weighted by its pool's weight
# ─────────────────────────────────────────────────────────────────────────────

locals {
  backends = flatten([
    for pool, m in module.vm_pool : [
      for i, name in m.vm_names : {
        name   = name
        pool   = pool
        ip     = m.vm_ips[i]
        weight = var.vm_pools[pool].weight
      }
    ]
  ])
}

resource "local_file" "haproxy_cfg" {
  filename = "${path.module}/out/haproxy.cfg"
  content = templatefile("${path.module}/templates/haproxy.cfg.tftpl", {
    listen_port = var.lb_port
    backends    = [for b in local.backends : b if b.ip != null]
  })
}
