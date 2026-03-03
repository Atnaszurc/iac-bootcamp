# TF-104 Test: State Management & CLI — single libvirt VM
# Uses: command = plan (libvirt requires a running daemon for apply)
# Provider: dmacvicar/libvirt (mocked — no libvirt daemon required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: terraform state, CLI workflow (init/plan/apply/show/destroy)
# This test validates the infrastructure students manage via CLI commands.

# mock_provider bypasses the real libvirt schema so tests run without a daemon
mock_provider "libvirt" {}

run "plan_default_vm" {
  command = plan

  assert {
    condition     = libvirt_domain.vm.name == "tf104-state"
    error_message = "VM domain name should equal project_name with default 'tf104-state'"
  }

  assert {
    condition     = libvirt_domain.vm.memory == 1024
    error_message = "Default VM memory should be 1024 MB"
  }

  assert {
    condition     = libvirt_domain.vm.vcpu == 1
    error_message = "Default vCPU count should be 1"
  }
}

run "plan_network_and_storage" {
  command = plan

  assert {
    condition     = libvirt_network.main.name == "tf104-state-net"
    error_message = "Network name should be '<project_name>-net'"
  }

  assert {
    condition     = libvirt_pool.main.name == "tf104-state-pool"
    error_message = "Pool name should be '<project_name>-pool'"
  }

  assert {
    condition     = libvirt_pool.main.type == "dir"
    error_message = "Pool type should be 'dir'"
  }
}

run "plan_with_custom_resources" {
  command = plan

  variables {
    project_name = "my-vm"
    memory_mb    = 2048
    vcpu_count   = 2
  }

  assert {
    condition     = libvirt_domain.vm.name == "my-vm"
    error_message = "VM domain name should use custom project_name"
  }

  assert {
    condition     = libvirt_domain.vm.memory == 2048
    error_message = "VM memory should reflect custom memory_mb"
  }

  assert {
    condition     = libvirt_domain.vm.vcpu == 2
    error_message = "vCPU count should reflect custom vcpu_count"
  }

  assert {
    condition     = libvirt_network.main.name == "my-vm-net"
    error_message = "Network name should use custom project_name"
  }
}