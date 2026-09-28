# TF-103 Test: Complete infrastructure stack (network + storage + VM)
# Uses: command = plan (libvirt requires a running daemon for apply)
# Provider: dmacvicar/libvirt (mocked — no libvirt daemon required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: libvirt_network, libvirt_pool, libvirt_volume,
#                 libvirt_cloudinit_disk, libvirt_domain
#
# mock_provider still uses the real provider schema, but Terraform silently
# drops unknown keys inside nested attributes (e.g. devices.disk instead of
# devices.disks). The "devices" assertions below catch that class of mistake.

mock_provider "libvirt" {}

run "plan_with_defaults" {
  command = plan

  assert {
    condition     = libvirt_network.example.name == "tf-103-network"
    error_message = "Network name should be '<project_name>-network' with default project_name 'tf-103'"
  }

  assert {
    condition     = libvirt_network.example.forward.mode == "nat"
    error_message = "Network should use NAT forwarding"
  }

  assert {
    condition     = libvirt_network.example.ips[0].address == "10.103.0.1"
    error_message = "Host address should be the first address of network_cidr"
  }

  assert {
    condition     = libvirt_network.example.ips[0].dhcp.ranges[0].start == "10.103.0.100"
    error_message = "DHCP range should start at .100"
  }

  assert {
    condition     = libvirt_pool.example.name == "tf-103-pool"
    error_message = "Pool name should be '<project_name>-pool' with default project_name 'tf-103'"
  }

  assert {
    condition     = libvirt_pool.example.type == "dir"
    error_message = "Pool type should be 'dir'"
  }

  assert {
    condition     = libvirt_domain.example.memory == 1024 && libvirt_domain.example.memory_unit == "MiB"
    error_message = "Default VM memory should be 1024 MiB"
  }

  assert {
    condition     = libvirt_domain.example.vcpu == 1
    error_message = "Default vCPU count should be 1"
  }

  assert {
    condition     = libvirt_domain.example.running == true
    error_message = "The VM should be started after creation"
  }
}

run "plan_attaches_devices" {
  command = plan

  assert {
    condition     = length(libvirt_domain.example.devices.disks) == 2
    error_message = "VM should have a system disk and a cloud-init CD-ROM"
  }

  assert {
    condition     = libvirt_domain.example.devices.disks[0].source.volume.volume == "tf-103-disk.qcow2"
    error_message = "First disk should be the VM's own volume"
  }

  assert {
    condition     = libvirt_domain.example.devices.disks[1].device == "cdrom"
    error_message = "Second disk should be the cloud-init CD-ROM"
  }

  assert {
    condition     = length(libvirt_domain.example.devices.interfaces) == 1
    error_message = "VM should have exactly one network interface"
  }

  assert {
    condition     = libvirt_domain.example.devices.interfaces[0].source.network.network == "tf-103-network"
    error_message = "Interface should be attached to the example network"
  }
}

run "plan_with_custom_project_name" {
  command = plan

  variables {
    project_name = "my-project"
    memory_mb    = 2048
    vcpu_count   = 2
    network_cidr = "192.168.150.0/24"
  }

  assert {
    condition     = libvirt_network.example.name == "my-project-network"
    error_message = "Network name should use custom project_name"
  }

  assert {
    condition     = libvirt_network.example.ips[0].address == "192.168.150.1"
    error_message = "Host address should follow a custom network_cidr"
  }

  assert {
    condition     = libvirt_pool.example.name == "my-project-pool"
    error_message = "Pool name should use custom project_name"
  }

  assert {
    condition     = libvirt_domain.example.name == "my-project-vm"
    error_message = "Domain name should be '<project_name>-vm'"
  }

  assert {
    condition     = libvirt_domain.example.memory == 2048
    error_message = "VM memory should reflect custom memory_mb value"
  }

  assert {
    condition     = libvirt_domain.example.vcpu == 2
    error_message = "vCPU count should reflect custom vcpu_count value"
  }
}

run "plan_validates_project_name_format" {
  command = plan

  variables {
    project_name = "valid-name-123"
  }

  assert {
    condition     = libvirt_network.example.name == "valid-name-123-network"
    error_message = "Alphanumeric project names with hyphens should be accepted"
  }
}

run "reject_invalid_cidr" {
  command = plan

  variables {
    network_cidr = "not-a-cidr"
  }

  expect_failures = [var.network_cidr]
}
