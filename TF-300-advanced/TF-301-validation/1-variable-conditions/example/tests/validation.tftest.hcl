# TF-301 Section 1: Variable conditions — tests
# Every validation rule gets a passing case and at least one failing case.
# libvirt is mocked: validation happens before any provider call anyway.

mock_provider "libvirt" {}

variables {
  vm_name        = "web-01"
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleKeyOnly student@laptop"
}

run "valid_defaults" {
  command = plan

  assert {
    condition     = local.ufw_rules == ["ufw allow 22/tcp"]
    error_message = "Default firewall rules should open SSH only"
  }
}

# ── vm_name ─────────────────────────────────────────────────────────────────

run "vm_name_rejects_uppercase_and_underscore" {
  command = plan
  variables {
    vm_name = "Web_01"
  }
  expect_failures = [var.vm_name]
}

run "vm_name_rejects_trailing_hyphen" {
  command = plan
  variables {
    vm_name = "web-"
  }
  expect_failures = [var.vm_name]
}

run "vm_name_accepts_single_character" {
  command = plan
  variables {
    vm_name = "a"
  }
}

# ── memory_mb ───────────────────────────────────────────────────────────────

run "memory_too_small" {
  command = plan
  variables {
    memory_mb = 256
  }
  expect_failures = [var.memory_mb]
}

run "memory_not_multiple_of_256" {
  command = plan
  variables {
    memory_mb = 1000
  }
  expect_failures = [var.memory_mb]
}

# ── network_cidr ────────────────────────────────────────────────────────────

run "cidr_accepts_private_ranges" {
  command = plan
  variables {
    network_cidr = "172.20.5.0/24"
  }
}

run "cidr_rejects_public_range" {
  command = plan
  variables {
    network_cidr = "8.8.8.0/24"
  }
  expect_failures = [var.network_cidr]
}

run "cidr_rejects_garbage" {
  command = plan
  variables {
    network_cidr = "not-a-cidr"
  }
  expect_failures = [var.network_cidr]
}

run "cidr_rejects_range_wider_than_private_block" {
  command = plan
  variables {
    network_cidr = "10.0.0.0/7"
  }
  expect_failures = [var.network_cidr]
}

# ── cross-variable ──────────────────────────────────────────────────────────

run "prod_needs_two_vms" {
  command = plan
  variables {
    environment    = "prod"
    vm_count       = 1
    firewall_rules = [{ port = 22, from = "10.0.0.0/8" }]
  }
  expect_failures = [var.vm_count]
}

run "prod_rejects_ssh_from_anywhere" {
  command = plan
  variables {
    environment = "prod"
    vm_count    = 2
  }
  expect_failures = [var.firewall_rules]
}

run "prod_with_restricted_ssh" {
  command = plan
  variables {
    environment = "prod"
    vm_count    = 2
    firewall_rules = [
      { port = 22, from = "10.0.0.0/8" },
      { port = 443 },
    ]
  }

  assert {
    condition     = local.ufw_rules == ["ufw allow from 10.0.0.0/8 to any port 22 proto tcp", "ufw allow 443/tcp"]
    error_message = "Rules should render to ufw commands"
  }
}

# ── ssh key and firewall rules ──────────────────────────────────────────────

run "rejects_private_key" {
  command = plan
  variables {
    ssh_public_key = "-----BEGIN OPENSSH PRIVATE KEY-----"
  }
  expect_failures = [var.ssh_public_key]
}

run "rejects_bad_port_and_protocol" {
  command = plan
  variables {
    firewall_rules = [{ port = 70000, protocol = "icmp" }]
  }
  expect_failures = [var.firewall_rules]
}
