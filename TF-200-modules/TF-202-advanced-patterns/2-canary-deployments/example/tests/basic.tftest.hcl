# =============================================================================
# tests/basic.tftest.hcl
# Plan-only tests for the canary / blue-green example.
#
# libvirt and random are mocked, so no daemon is needed. override_during = plan
# makes the mocked values (generation suffix, VM IPs) known at plan time, so
# the tests can check names and the generated HAProxy config.
# =============================================================================

mock_provider "libvirt" {
  override_during = plan

  mock_data "libvirt_domain_interface_addresses" {
    defaults = {
      interfaces = [
        {
          name   = "vnet0"
          hwaddr = "52:54:00:00:00:01"
          addrs  = [{ addr = "10.210.0.150", prefix = 24, type = "ipv4" }]
        }
      ]
    }
  }
}

mock_provider "random" {
  override_during = plan

  mock_resource "random_id" {
    defaults = {
      hex = "beef"
    }
  }
}

variables {
  blue = {
    base_image_url = "https://example.invalid/jammy.img"
    vm_count       = 2
    weight         = 90
  }
  green = {
    base_image_url = "https://example.invalid/noble.img"
    vm_count       = 1
    weight         = 10
  }
}

# ---------------------------------------------------------------------------
# Default: a single blue pool with two VMs
# ---------------------------------------------------------------------------
run "default_blue_pool" {
  command = plan

  assert {
    condition     = keys(module.vm_pool) == ["blue"]
    error_message = "Default configuration should deploy only the blue pool"
  }

  assert {
    condition     = module.vm_pool["blue"].vm_names == ["blue-beef-vm-0", "blue-beef-vm-1"]
    error_message = "VM names should be <pool>-<generation>-vm-<index>"
  }

  assert {
    condition     = length(local.backends) == 2 && alltrue([for b in local.backends : b.weight == 100])
    error_message = "Both blue VMs should be load balancer backends with the default weight 100"
  }
}

# ---------------------------------------------------------------------------
# Canary: green next to blue, 10% weight
# ---------------------------------------------------------------------------
run "canary_pool_alongside_blue" {
  command = plan

  variables {
    vm_pools = {
      blue  = var.blue
      green = var.green
    }
  }

  assert {
    condition     = length(module.vm_pool) == 2
    error_message = "Adding green should give two pools"
  }

  assert {
    condition     = length(local.backends) == 3
    error_message = "Two blue VMs and one green VM should all be backends"
  }

  # The VM IPs (and so the rendered config) are only known after apply.
  # Names and weights are known at plan time.
  assert {
    condition     = one([for b in local.backends : b.weight if b.name == "green-beef-vm-0"]) == 10
    error_message = "The green VM should be a backend with weight 10"
  }

  assert {
    condition     = one([for b in local.backends : b.weight if b.name == "blue-beef-vm-1"]) == 90
    error_message = "Blue VMs should be backends with weight 90"
  }
}

# ---------------------------------------------------------------------------
# The HAProxy template on its own, with known IPs
# ---------------------------------------------------------------------------
run "haproxy_template_renders_weights" {
  command = plan

  assert {
    condition = strcontains(
      templatefile("${path.module}/templates/haproxy.cfg.tftpl", {
        listen_port = 8080
        backends = [
          { name = "blue-beef-vm-0", pool = "blue", ip = "10.210.0.101", weight = 90 },
          { name = "green-beef-vm-0", pool = "green", ip = "10.210.0.102", weight = 10 },
        ]
      }),
      "server green-beef-vm-0 10.210.0.102:80 weight 10 check"
    )
    error_message = "Each backend should render as 'server <name> <ip>:80 weight <weight> check'"
  }

  assert {
    condition = strcontains(
      templatefile("${path.module}/templates/haproxy.cfg.tftpl", { listen_port = 9000, backends = [] }),
      "bind *:9000"
    )
    error_message = "The frontend should listen on listen_port"
  }
}

# ---------------------------------------------------------------------------
# Cutover: only green remains
# ---------------------------------------------------------------------------
run "cutover_to_green" {
  command = plan

  variables {
    vm_pools = {
      green = merge(var.green, { weight = 100, vm_count = 2 })
    }
  }

  assert {
    condition     = keys(module.vm_pool) == ["green"]
    error_message = "After cutover only the green pool should remain"
  }

  assert {
    condition     = length(local.backends) == 2 && alltrue([for b in local.backends : b.pool == "green"])
    error_message = "Only the two green VMs should remain behind the load balancer"
  }
}

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
run "reject_all_zero_weights" {
  command = plan

  variables {
    vm_pools = {
      blue = merge(var.blue, { weight = 0 })
    }
  }

  expect_failures = [var.vm_pools]
}

run "reject_weight_above_256" {
  command = plan

  variables {
    vm_pools = {
      blue = merge(var.blue, { weight = 300 })
    }
  }

  expect_failures = [var.vm_pools]
}

# ---------------------------------------------------------------------------
# The pool module on its own: devices and create_before_destroy wiring
# ---------------------------------------------------------------------------
run "vm_pool_module_devices" {
  command = plan

  module {
    source = "./modules/libvirt-vm"
  }

  variables {
    pool_name      = "green"
    base_image_url = "https://example.invalid/noble.img"
    ssh_public_key = "ssh-ed25519 AAAA test"
    storage_pool   = "canary-pool"
    network_name   = "canary-net"
    vm_count       = 2
    memory_mb      = 512
  }

  assert {
    condition     = libvirt_domain.vm[1].name == "green-beef-vm-1"
    error_message = "VM names should include the generation suffix"
  }

  assert {
    condition     = libvirt_domain.vm[0].memory == 512 && libvirt_domain.vm[0].memory_unit == "MiB"
    error_message = "memory_mb should reach the domain as MiB"
  }

  assert {
    condition     = length(libvirt_domain.vm[0].devices.disks) == 2 && libvirt_domain.vm[0].devices.interfaces[0].source.network.network == "canary-net"
    error_message = "Each VM needs a system disk, a cloud-init CD-ROM and a NIC on the shared network"
  }

  assert {
    condition     = strcontains(libvirt_cloudinit_disk.vm[0].user_data, "pool=green vm=0")
    error_message = "The web page should say which pool and VM answered"
  }
}
