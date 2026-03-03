# TF-103/3-virtual-machines Test: libvirt VMs with for_each over a map variable
# Uses: command = plan (libvirt requires a running daemon for apply)
# Provider: dmacvicar/libvirt (mocked — no libvirt daemon required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: for_each over map, per-VM disk/cloud-init/domain resources

# mock_provider bypasses the real libvirt schema so tests run without a daemon
mock_provider "libvirt" {}

run "plan_default_vms" {
  command = plan

  assert {
    condition     = length(libvirt_domain.vm) == 2
    error_message = "Default vms map should create 2 VM domains (web + db)"
  }

  assert {
    condition     = length(libvirt_volume.vm_disk) == 2
    error_message = "Should create 2 VM disks (one per VM)"
  }

  assert {
    condition     = length(libvirt_cloudinit_disk.vm_init) == 2
    error_message = "Should create 2 cloud-init disks (one per VM)"
  }
}

run "plan_network_and_pool" {
  command = plan

  assert {
    condition     = libvirt_network.vm_network.name == "tf103-vms-vm-net"
    error_message = "VM network name should be '<project_name>-vm-net' with default project_name 'tf103-vms'"
  }

  assert {
    condition     = libvirt_pool.vms.name == "tf103-vms-vms"
    error_message = "Storage pool name should be '<project_name>-vms'"
  }
}

run "plan_with_single_vm" {
  command = plan

  variables {
    project_name = "test-proj"
    vms = {
      app = {
        memory_mb       = 512
        vcpu_count      = 1
        disk_size_bytes = 5368709120
      }
    }
  }

  assert {
    condition     = length(libvirt_domain.vm) == 1
    error_message = "Custom vms map with 1 entry should create 1 VM domain"
  }

  assert {
    condition     = libvirt_network.vm_network.name == "test-proj-vm-net"
    error_message = "Network name should use custom project_name"
  }
}

run "plan_with_three_vms" {
  command = plan

  variables {
    vms = {
      web = {
        memory_mb       = 1024
        vcpu_count      = 1
        disk_size_bytes = 10737418240
      }
      db = {
        memory_mb       = 2048
        vcpu_count      = 2
        disk_size_bytes = 21474836480
      }
      cache = {
        memory_mb       = 512
        vcpu_count      = 1
        disk_size_bytes = 5368709120
      }
    }
  }

  assert {
    condition     = length(libvirt_domain.vm) == 3
    error_message = "Custom vms map with 3 entries should create 3 VM domains"
  }
}