# TF-104/3-modules-intro Test: root module calling a local child module
# Uses: command = plan (libvirt requires a running daemon for apply)
# Provider: dmacvicar/libvirt (mocked — no libvirt daemon required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: module composition — root module calls ./modules/vm/ twice
# (web VM and db VM), each with different memory/vcpu/network_cidr

# mock_provider bypasses the real libvirt schema so tests run without a daemon
mock_provider "libvirt" {}

run "plan_two_module_instances" {
  command = plan

  # The root module calls module.web_vm and module.db_vm
  # Both use the same ./modules/vm/ source but different inputs
  assert {
    condition     = module.web_vm.ip_address != null
    error_message = "web_vm module should expose an ip_address output"
  }

  assert {
    condition     = module.db_vm.ip_address != null
    error_message = "db_vm module should expose an ip_address output"
  }
}

run "plan_outputs_defined" {
  command = plan

  assert {
    condition     = output.web_vm_ip != null
    error_message = "web_vm_ip output should be defined"
  }

  assert {
    condition     = output.db_vm_ip != null
    error_message = "db_vm_ip output should be defined"
  }
}

run "plan_with_custom_project_name" {
  command = plan

  variables {
    project_name = "custom-proj"
  }

  # Verify the module instances still resolve correctly with custom project_name
  assert {
    condition     = module.web_vm.ip_address != null
    error_message = "web_vm module should still expose ip_address with custom project_name"
  }

  assert {
    condition     = module.db_vm.ip_address != null
    error_message = "db_vm module should still expose ip_address with custom project_name"
  }
}