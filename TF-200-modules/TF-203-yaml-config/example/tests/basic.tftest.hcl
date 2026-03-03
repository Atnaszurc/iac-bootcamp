# TF-203 Test: YAML-Driven Configuration — libvirt VMs defined in vms.yaml
# Uses: command = plan (libvirt requires a running daemon for apply)
# Provider: dmacvicar/libvirt
# Run: terraform test (from the example/ directory)
#
# Teaching focus: yamldecode(), locals with for_each, YAML-driven resource creation
# The vms.yaml file defines 3 VMs: web-server, db-server, cache-server

run "plan_yaml_driven_vms" {
  command = plan

  # vms.yaml defines 3 VMs: web-server, db-server, cache-server
  assert {
    condition     = length(libvirt_domain.vm) == 3
    error_message = "vms.yaml defines 3 VMs — should create 3 libvirt_domain resources"
  }

  assert {
    condition     = length(libvirt_network.vm) == 3
    error_message = "Should create 3 networks (one per VM from YAML)"
  }

  assert {
    condition     = length(libvirt_volume.vm) == 3
    error_message = "Should create 3 VM disks (one per VM from YAML)"
  }

  assert {
    condition     = length(libvirt_cloudinit_disk.vm) == 3
    error_message = "Should create 3 cloud-init disks (one per VM from YAML)"
  }
}

run "plan_shared_resources" {
  command = plan

  assert {
    condition     = libvirt_pool.main.name == "tf203-pool"
    error_message = "Shared storage pool should be named 'tf203-pool'"
  }

  assert {
    condition     = libvirt_pool.main.type == "dir"
    error_message = "Storage pool type should be 'dir'"
  }

  assert {
    condition     = libvirt_volume.base.name == "tf203-base.qcow2"
    error_message = "Base volume should be named 'tf203-base.qcow2'"
  }
}

run "plan_vm_names_from_yaml" {
  command = plan

  assert {
    condition     = contains(keys(libvirt_domain.vm), "web-server")
    error_message = "Should have a VM named 'web-server' as defined in vms.yaml"
  }

  assert {
    condition     = contains(keys(libvirt_domain.vm), "db-server")
    error_message = "Should have a VM named 'db-server' as defined in vms.yaml"
  }

  assert {
    condition     = contains(keys(libvirt_domain.vm), "cache-server")
    error_message = "Should have a VM named 'cache-server' as defined in vms.yaml"
  }
}

run "plan_output_vm_names" {
  command = plan

  assert {
    condition     = length(output.vm_names) == 3
    error_message = "vm_names output should list all 3 VM names from YAML"
  }
}