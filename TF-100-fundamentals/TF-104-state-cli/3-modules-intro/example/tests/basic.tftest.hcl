# TF-104/3-modules-intro Test: root module calling a local child module
# Uses: command = plan (libvirt requires a running daemon for apply)
# Provider: dmacvicar/libvirt (mocked — no libvirt daemon required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: module composition — root module calls ./modules/vm/ twice
# (web VM and db VM), each with different memory/vcpu/network_cidr

# mock_provider fakes provider responses so tests run without a daemon
mock_provider "libvirt" {}

run "plan_two_module_instances" {
  command = plan

  # The root module calls module.web_vm and module.db_vm
  # Both use the same ./modules/vm/ source but different inputs
  assert {
    condition     = module.web_vm.vm_name == "tf104-modules-web"
    error_message = "web_vm module should name its VM '<project_name>-web'"
  }

  assert {
    condition     = module.db_vm.vm_name == "tf104-modules-db"
    error_message = "db_vm module should name its VM '<project_name>-db'"
  }
}

# Assertions in the root module can only see a child module's OUTPUTS.
# To check the resources inside the module, test the module on its own:
# the module block makes ./modules/vm the configuration under test.
run "vm_module_in_isolation" {
  command = plan

  module {
    source = "./modules/vm"
  }

  variables {
    vm_name        = "unit"
    base_image_url = "https://example.invalid/base.qcow2"
    ssh_public_key = "ssh-ed25519 AAAA test"
    memory_mb      = 2048
    network_cidr   = "10.50.9.0/24"
  }

  assert {
    condition     = libvirt_domain.this.memory == 2048 && libvirt_domain.this.memory_unit == "MiB"
    error_message = "memory_mb should reach the domain as MiB"
  }

  assert {
    condition     = libvirt_network.this.ips[0].address == "10.50.9.1"
    error_message = "The module network should be built from network_cidr"
  }

  assert {
    condition     = length(libvirt_domain.this.devices.disks) == 2 && length(libvirt_domain.this.devices.interfaces) == 1
    error_message = "Module VM should have a system disk, a cloud-init CD-ROM and one NIC"
  }
}

run "plan_with_custom_project_name" {
  command = plan

  variables {
    project_name = "custom-proj"
  }

  assert {
    condition     = module.web_vm.vm_name == "custom-proj-web"
    error_message = "web_vm should follow a custom project_name"
  }

  assert {
    condition     = module.db_vm.vm_name == "custom-proj-db"
    error_message = "db_vm should follow a custom project_name"
  }
}
