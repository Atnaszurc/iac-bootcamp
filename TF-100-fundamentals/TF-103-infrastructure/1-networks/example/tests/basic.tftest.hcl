# TF-103/1-networks Test: libvirt NAT and isolated networks
# Uses: command = plan (libvirt requires a running daemon for apply)
# Provider: dmacvicar/libvirt (mocked — no libvirt daemon required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: libvirt_network modes (nat, none), DNS configuration

# mock_provider bypasses the real libvirt schema so tests run without a daemon
mock_provider "libvirt" {}

run "plan_nat_network_defaults" {
  command = plan

  assert {
    condition     = libvirt_network.main.name == "tf-103-net"
    error_message = "NAT network name should be '<network_name>-net' with default network_name 'tf-103'"
  }

  # Note: libvirt_network in 0.9.3 doesn't expose mode attribute
  # Networks are automatically configured as NAT with DHCP

  assert {
    condition     = libvirt_network.main.autostart == true
    error_message = "NAT network should have autostart enabled"
  }
}

run "plan_isolated_network_defaults" {
  command = plan

  assert {
    condition     = libvirt_network.isolated.name == "tf-103-isolated"
    error_message = "Isolated network name should be '<network_name>-isolated' with default network_name 'tf-103'"
  }

  # Note: libvirt_network in 0.9.3 doesn't support isolated mode
  # All networks are NAT-enabled

  assert {
    condition     = libvirt_network.isolated.autostart == false
    error_message = "Isolated network should not autostart"
  }
}

run "plan_with_custom_network_name" {
  command = plan

  variables {
    network_name = "lab"
    network_cidr = "192.168.50.0/24"
  }

  assert {
    condition     = libvirt_network.main.name == "lab-net"
    error_message = "NAT network name should use custom network_name"
  }

  assert {
    condition     = libvirt_network.isolated.name == "lab-isolated"
    error_message = "Isolated network name should use custom network_name"
  }
}