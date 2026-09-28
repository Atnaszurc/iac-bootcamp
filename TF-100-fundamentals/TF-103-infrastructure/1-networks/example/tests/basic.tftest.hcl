# TF-103/1-networks Test: libvirt NAT and isolated networks
# Uses: command = plan (libvirt requires a running daemon for apply)
# Provider: dmacvicar/libvirt (mocked — no libvirt daemon required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: forward mode (nat vs none), ips + DHCP ranges, DNS

# mock_provider fakes provider responses so tests run without a daemon
mock_provider "libvirt" {}

run "plan_nat_network_defaults" {
  command = plan

  assert {
    condition     = libvirt_network.main.name == "tf-103-net"
    error_message = "NAT network name should be '<network_name>-net' with default network_name 'tf-103'"
  }

  assert {
    condition     = libvirt_network.main.forward.mode == "nat"
    error_message = "Main network should forward traffic with NAT"
  }

  assert {
    condition     = libvirt_network.main.ips[0].address == "10.10.0.1" && libvirt_network.main.ips[0].prefix == 24
    error_message = "Host address should be 10.10.0.1/24 for the default CIDR"
  }

  assert {
    condition     = libvirt_network.main.ips[0].dhcp.ranges[0].start == "10.10.0.100" && libvirt_network.main.ips[0].dhcp.ranges[0].end == "10.10.0.200"
    error_message = "DHCP should hand out .100 to .200"
  }

  assert {
    condition     = libvirt_network.main.domain.name == "tf-103.local" && libvirt_network.main.dns.enable == "yes"
    error_message = "DNS should be enabled for the tf-103.local domain"
  }

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

  assert {
    condition     = libvirt_network.isolated.forward == null
    error_message = "An isolated network must not have a forward mode"
  }

  assert {
    condition     = libvirt_network.isolated.ips[0].dhcp == null
    error_message = "The isolated network uses static addressing (no DHCP)"
  }

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

  assert {
    condition     = libvirt_network.main.ips[0].address == "192.168.50.1"
    error_message = "Host address should follow the custom CIDR"
  }
}

run "reject_invalid_cidr" {
  command = plan

  variables {
    network_cidr = "10.10.0.0/33"
  }

  expect_failures = [var.network_cidr]
}
