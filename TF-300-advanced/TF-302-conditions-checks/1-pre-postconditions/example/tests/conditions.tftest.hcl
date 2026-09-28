# TF-302 Section 1: Pre- and postconditions — tests
#
# libvirt is mocked, so these run without a daemon. With a mock provider,
# command = apply is safe: nothing is created, but postconditions run on the
# mocked values. Each run sets the values its conditions look at with
# override_resource, so every run shows exactly what it tests.
#
# The apply runs target libvirt_domain.vm (and so everything it depends on),
# leaving out data.libvirt_domain_interface_addresses.vm: Terraform 1.16/1.17
# can't mock a computed *nested list* attribute like its "interfaces"
# ("incompatible types; expected object type, found tuple"). The IP
# postcondition is covered by a real apply instead (see the README).

mock_provider "libvirt" {
  mock_data "libvirt_node_info" {
    defaults = {
      memory_total_kb = 16777216 # a 16 GiB host
    }
  }

  # Volumes without a configured capacity (the downloaded base image) report
  # the Ubuntu 22.04 image size: 2.2 GiB. Mock defaults only fill values the
  # configuration doesn't set, so the VM disk keeps its own capacity.
  mock_resource "libvirt_volume" {
    defaults = {
      capacity = 2361393152
      path     = "/var/lib/libvirt/images/mock.qcow2"
    }
  }
}

# ── Everything passes ───────────────────────────────────────────────────────

run "all_conditions_pass" {
  command = apply

  plan_options {
    target = [libvirt_domain.vm]
  }

  override_resource {
    target = libvirt_pool.main
    values = {
      available = 107374182400 # 100 GiB free
    }
  }

  override_resource {
    target = libvirt_domain.vm
    values = {
      running = true
    }
  }

  assert {
    condition     = libvirt_domain.vm.running && length(libvirt_domain.vm.devices.interfaces) == 1
    error_message = "The VM should be running with one network interface"
  }
}

# ── Preconditions (checked before the resource is created) ──────────────────

run "network_overlapping_default_network" {
  command = plan
  variables {
    network_cidr = "192.168.0.0/16"
  }
  expect_failures = [libvirt_network.main]
}

run "network_overlap_is_symmetric" {
  command = plan
  variables {
    network_cidr   = "10.150.0.0/24"
    reserved_cidrs = ["10.0.0.0/8"]
  }
  expect_failures = [libvirt_network.main]
}

run "vm_memory_more_than_half_the_host" {
  command = plan
  variables {
    memory_mb = 10240 # 10 GiB on a 16 GiB host
  }
  expect_failures = [libvirt_domain.vm]
}

# The image size is only known after the download, so this precondition
# normally runs during apply. override_during = plan makes the base image's
# size known at plan time, where expect_failures can catch the failure.
run "disk_smaller_than_base_image" {
  command = plan

  variables {
    disk_gib = 2 # smaller than the 2.2 GiB image
  }

  override_resource {
    target          = libvirt_volume.base
    override_during = plan
    values = {
      capacity = 2361393152
      path     = "/var/lib/libvirt/images/base.qcow2"
    }
  }

  expect_failures = [libvirt_volume.disk]
}

# ── Postconditions (checked after the resource is created or read) ──────────
# Runs share state by default. These runs use their own state_key
# (Terraform 1.11+) so their resources are created fresh, with the
# overridden values, instead of reusing what all_conditions_pass created.

run "pool_without_enough_free_space" {
  command   = apply
  state_key = "pool_test" # fresh state: the resource must be *created* with the override

  plan_options {
    target = [libvirt_pool.main]
  }

  override_resource {
    target = libvirt_pool.main
    values = {
      available = 1073741824 # 1 GiB
    }
  }

  expect_failures = [libvirt_pool.main]
}

# Not tested here: the "running" postcondition. The configuration sets
# running = true, and overrides only replace values the provider computes,
# so a mock always reports what the configuration asked for. That
# postcondition exists to catch a real VM that libvirt couldn't start.
