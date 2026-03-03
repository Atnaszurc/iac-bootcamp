# TF-103 Test: Complete infrastructure stack (network + storage + VM)
# Uses: command = plan (libvirt requires a running daemon for apply)
# Provider: dmacvicar/libvirt (mocked — no libvirt daemon required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: libvirt_network, libvirt_pool, libvirt_volume,
#                 libvirt_cloudinit_disk, libvirt_domain

# mock_provider replaces the libvirt schema entirely — no daemon or real provider needed.
# All attributes used in main.tf must be declared here so HCL validation passes.
mock_provider "libvirt" {
  mock_resource "libvirt_network" {
    defaults = {
      id        = "mock-network-id"
      name      = "mock-network"
      mode      = "nat"
      addresses = ["10.10.0.0/24"]
      autostart = true
    }
  }
  mock_resource "libvirt_pool" {
    defaults = {
      id   = "mock-pool-id"
      name = "mock-pool"
      type = "dir"
    }
  }
  mock_resource "libvirt_volume" {
    defaults = {
      id   = "mock-volume-id"
      name = "mock-volume"
    }
  }
  mock_resource "libvirt_cloudinit_disk" {
    defaults = {
      id   = "mock-cloudinit-id"
      name = "mock-cloudinit.iso"
    }
  }
  mock_resource "libvirt_domain" {
    defaults = {
      id     = "mock-domain-id"
      name   = "mock-vm"
      memory = 1024
      vcpu   = 1
    }
  }
}

run "plan_with_defaults" {
  command = plan

  assert {
    condition     = libvirt_network.example.name == "tf-103-network"
    error_message = "Network name should be '<project_name>-network' with default project_name 'tf-103'"
  }

  # Note: libvirt_network in 0.9.3 doesn't expose mode attribute
  # Networks are automatically configured as NAT with DHCP

  assert {
    condition     = libvirt_pool.example.name == "tf-103-pool"
    error_message = "Pool name should be '<project_name>-pool' with default project_name 'tf-103'"
  }

  assert {
    condition     = libvirt_pool.example.type == "dir"
    error_message = "Pool type should be 'dir'"
  }

  assert {
    condition     = libvirt_domain.example.memory == 1024
    error_message = "Default VM memory should be 1024 MB"
  }

  assert {
    condition     = libvirt_domain.example.vcpu == 1
    error_message = "Default vCPU count should be 1"
  }
}

run "plan_with_custom_project_name" {
  command = plan

  variables {
    project_name = "my-project"
    memory_mb    = 2048
    vcpu_count   = 2
  }

  assert {
    condition     = libvirt_network.example.name == "my-project-network"
    error_message = "Network name should use custom project_name"
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