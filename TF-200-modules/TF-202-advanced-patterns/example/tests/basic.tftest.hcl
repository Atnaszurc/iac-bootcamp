# TF-202 Test: Advanced Module Patterns — root module calling ./modules/libvirt/
# Uses: command = plan (libvirt requires a running daemon for apply)
# Provider: dmacvicar/libvirt
# Run: terraform test (from the example/ directory)
#
# Teaching focus: module composition, passing variables to child modules,
#                 consuming module outputs in the root module

run "plan_module_with_defaults" {
  command = plan

  # The root module calls module.vm which exposes ip_address output
  assert {
    condition     = module.vm.ip_address != null
    error_message = "Child module should expose an ip_address output"
  }
}

run "plan_vm_output_exposed" {
  command = plan

  assert {
    condition     = output.vm_ip != null
    error_message = "Root module should expose vm_ip output from child module"
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
    condition     = module.vm.ip_address != null
    error_message = "Child module should still expose ip_address with custom vm_name"
  }
}

run "plan_with_minimal_resources" {
  command = plan

  variables {
    vm_name    = "tiny-vm"
    memory_mb  = 512
    vcpu_count = 1
  }

  assert {
    condition     = module.vm.ip_address != null
    error_message = "Child module should work with minimal resource allocation"
  }
}