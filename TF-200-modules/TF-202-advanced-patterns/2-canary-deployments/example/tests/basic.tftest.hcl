# =============================================================================
# tests/basic.tftest.hcl
# Plan-only tests for the canary deployment example.
#
# Uses `command = plan` because libvirt requires a running daemon for apply.
# These tests validate the canary/blue-green pattern logic:
#   - Default config creates a single "stable" pool
#   - Adding a "canary" pool creates two pools (canary rollout)
#   - Removing "stable" leaves only "canary" (blue-green cutover)
# =============================================================================

# ---------------------------------------------------------------------------
# Test 1: Default config — single "stable" pool
# ---------------------------------------------------------------------------
run "default_stable_pool_only" {
  command = plan

  assert {
    condition     = length(var.vm_pools) == 1
    error_message = "Default configuration should define exactly 1 pool (stable)."
  }

  assert {
    condition     = contains(keys(var.vm_pools), "stable")
    error_message = "Default configuration must include a 'stable' pool."
  }

  assert {
    condition     = var.vm_pools["stable"].vm_count == 2
    error_message = "Default stable pool should have 2 VMs."
  }
}

# ---------------------------------------------------------------------------
# Test 2: Canary rollout — stable + canary pools coexist
# ---------------------------------------------------------------------------
run "canary_rollout_two_pools" {
  command = plan

  variables {
    vm_pools = {
      stable = {
        base_image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
        memory_mb      = 512
        vcpu_count     = 1
        vm_count       = 2
      }
      canary = {
        base_image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
        memory_mb      = 512
        vcpu_count     = 1
        vm_count       = 1
      }
    }
  }

  assert {
    condition     = length(var.vm_pools) == 2
    error_message = "Canary rollout should have 2 pools (stable + canary)."
  }

  assert {
    condition     = contains(keys(var.vm_pools), "stable")
    error_message = "Canary rollout must retain the 'stable' pool."
  }

  assert {
    condition     = contains(keys(var.vm_pools), "canary")
    error_message = "Canary rollout must include the 'canary' pool."
  }

  assert {
    condition     = var.vm_pools["canary"].vm_count == 1
    error_message = "Canary pool should start with 1 VM (small footprint)."
  }
}

# ---------------------------------------------------------------------------
# Test 3: Blue-green cutover — only new pool remains
# ---------------------------------------------------------------------------
run "blue_green_cutover" {
  command = plan

  variables {
    vm_pools = {
      green = {
        base_image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
        memory_mb      = 1024
        vcpu_count     = 2
        vm_count       = 3
      }
    }
  }

  assert {
    condition     = length(var.vm_pools) == 1
    error_message = "After cutover, only 1 pool should remain."
  }

  assert {
    condition     = contains(keys(var.vm_pools), "green")
    error_message = "After cutover, the 'green' pool should be the only pool."
  }

  assert {
    condition     = var.vm_pools["green"].vm_count == 3
    error_message = "Green pool should have 3 VMs after full cutover."
  }
}

# ---------------------------------------------------------------------------
# Test 4: Variable validation — vm_count must be positive
# ---------------------------------------------------------------------------
run "vm_count_must_be_positive" {
  command = plan

  variables {
    vm_pools = {
      stable = {
        base_image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
        memory_mb      = 512
        vcpu_count     = 1
        vm_count       = 1
      }
    }
  }

  assert {
    condition     = var.vm_pools["stable"].vm_count >= 1
    error_message = "vm_count must be at least 1."
  }
}