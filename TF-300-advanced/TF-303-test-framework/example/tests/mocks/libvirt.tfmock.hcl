# TF-303: Terraform Test Framework — Libvirt Mock Provider File
#
# This is a `.tfmock.hcl` file — a reusable mock definition that can be
# referenced from multiple test files using the `source` attribute:
#
#   mock_provider "libvirt" {
#     source = "./tests/mocks/libvirt.tfmock.hcl"
#   }
#
# Mock files let you define synthetic provider behaviour ONCE and reuse it
# across many test files, keeping your tests DRY.
#
# This file mocks the `dmacvicar/libvirt` provider for unit testing
# Terraform configurations that manage KVM/QEMU virtual infrastructure.
#
# Usage in a test file:
#   mock_provider "libvirt" {
#     source = "./tests/mocks/libvirt.tfmock.hcl"
#   }
#
# See: https://developer.hashicorp.com/terraform/language/tests/mocking

# ─────────────────────────────────────────────────────────────────────────────
# Mock: libvirt_network
#
# Provides synthetic values for computed attributes that the real provider
# would set after creating the network (id, bridge interface name).
# ─────────────────────────────────────────────────────────────────────────────

mock_resource "libvirt_network" {
  defaults = {
    # Computed by provider after creation
    id     = "mock-network-uuid-1234"
    bridge = "virbr1"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Mock: libvirt_volume
#
# Provides synthetic values for computed attributes on storage volumes.
# ─────────────────────────────────────────────────────────────────────────────

mock_resource "libvirt_volume" {
  defaults = {
    # Computed by provider after creation
    id = "mock-volume-uuid-5678"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Mock: libvirt_domain (virtual machine)
#
# Provides synthetic values for computed attributes on VM domains.
# ─────────────────────────────────────────────────────────────────────────────

mock_resource "libvirt_domain" {
  defaults = {
    # Computed by provider after creation
    id = "mock-domain-uuid-9012"

    # Network interface computed values
    network_interface = [
      {
        addresses      = ["192.168.100.100"]
        mac            = "52:54:00:ab:cd:ef"
        hostname       = "mock-vm"
        wait_for_lease = false
      }
    ]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Mock: libvirt_cloudinit_disk
#
# Provides synthetic values for cloud-init ISO disk resources.
# ─────────────────────────────────────────────────────────────────────────────

mock_resource "libvirt_cloudinit_disk" {
  defaults = {
    id = "mock-cloudinit-uuid-3456"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Mock: libvirt_pool (storage pool)
# ─────────────────────────────────────────────────────────────────────────────

mock_resource "libvirt_pool" {
  defaults = {
    id = "mock-pool-uuid-7890"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Example: How to use this mock file in a test
#
# Create a test file (e.g., tests/vm_unit.tftest.hcl) with:
#
#   mock_provider "libvirt" {
#     source = "./tests/mocks/libvirt.tfmock.hcl"
#   }
#
#   variables {
#     vm_name      = "test-vm"
#     network_name = "test-net"
#     vm_memory    = 2048
#     vm_vcpu      = 2
#   }
#
#   run "test_vm_naming" {
#     command = plan
#
#     assert {
#       condition     = libvirt_domain.vm.name == var.vm_name
#       error_message = "VM name mismatch"
#     }
#   }
#
#   run "test_resource_limits" {
#     command = plan
#
#     assert {
#       condition     = libvirt_domain.vm.memory == 2048
#       error_message = "VM memory should be 2048 MB"
#     }
#
#     assert {
#       condition     = libvirt_domain.vm.vcpu == 2
#       error_message = "VM should have 2 vCPUs"
#     }
#   }
#
#   run "test_network_config" {
#     command = plan
#
#     assert {
#       condition     = libvirt_network.vm_network.mode == "nat"
#       error_message = "Network mode should be nat"
#     }
#
#     assert {
#       condition     = libvirt_domain.vm.id == "mock-domain-uuid-9012"
#       error_message = "Mock domain ID should be set"
#     }
#   }
# ─────────────────────────────────────────────────────────────────────────────