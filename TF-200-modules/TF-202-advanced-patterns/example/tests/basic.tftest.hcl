# TF-202 Test: Advanced Module Patterns — root module calling ./modules/libvirt/
# Uses: command = plan (libvirt requires a running daemon for apply)
# Provider: dmacvicar/libvirt (mocked — no libvirt daemon required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: module composition, passing variables to child modules,
#                 consuming module outputs in the root module

mock_provider "libvirt" {}

run "plan_module_with_defaults" {
  command = plan

  # The root module can only see the child module's outputs
  assert {
    condition     = module.vm.vm_name == "tf202-vm"
    error_message = "Child module should expose the VM name as an output"
  }
}

run "plan_with_custom_vm_name" {
  command = plan

  variables {
    vm_name    = "my-custom-vm"
    memory_mb  = 2048
    vcpu_count = 2
  }

  assert {
    condition     = module.vm.vm_name == "my-custom-vm"
    error_message = "Child module should use the vm_name passed from the root"
  }
}

# Test the child module on its own to check the resources inside it
run "libvirt_module_in_isolation" {
  command = plan

  module {
    source = "./modules/libvirt"
  }

  variables {
    vm_name        = "tiny-vm"
    base_image_url = "https://example.invalid/base.qcow2"
    ssh_public_key = "ssh-ed25519 AAAA test"
    memory_mb      = 512
  }

  assert {
    condition     = libvirt_domain.this.memory == 512 && libvirt_domain.this.memory_unit == "MiB"
    error_message = "memory_mb should reach the domain as MiB"
  }

  assert {
    condition     = libvirt_domain.this.devices.interfaces[0].source.network.network == "tiny-vm-net"
    error_message = "The VM should be attached to the module's own network"
  }

  assert {
    condition     = length(libvirt_domain.this.devices.disks) == 2
    error_message = "The VM should have a system disk and a cloud-init CD-ROM"
  }
}
