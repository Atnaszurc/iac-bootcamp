# TF-103/2-security Test: libvirt network with security hardening via cloud-init
# Uses: command = plan (libvirt requires a running daemon for apply)
# Provider: dmacvicar/libvirt (mocked — no libvirt daemon required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: cloud-init security hardening (ufw, fail2ban, SSH key auth)

# mock_provider fakes provider responses so tests run without a daemon
mock_provider "libvirt" {}

run "plan_secure_network_defaults" {
  command = plan

  assert {
    condition     = libvirt_network.secure.name == "tf-103-secure-net"
    error_message = "Secure network name should be '<project_name>-secure-net' with default project_name 'tf-103'"
  }

  assert {
    condition     = libvirt_network.secure.autostart == true
    error_message = "Secure network should have autostart enabled"
  }

  assert {
    condition     = libvirt_network.secure.ips[0].dhcp.ranges[0].start == "10.30.0.100" && libvirt_network.secure.ips[0].dhcp.ranges[0].end == "10.30.0.109"
    error_message = "DHCP range should be limited to 10 addresses (.100-.109)"
  }

  assert {
    condition     = libvirt_network.secure.ips[0].dhcp.hosts[0].ip == "10.30.0.10"
    error_message = "The hardened VM should have a static DHCP lease at .10"
  }
}

run "plan_secure_pool_defaults" {
  command = plan

  assert {
    condition     = libvirt_pool.secure.name == "tf-103-secure-pool"
    error_message = "Secure pool name should be '<project_name>-secure-pool' with default project_name 'tf-103'"
  }

  assert {
    condition     = libvirt_pool.secure.type == "dir"
    error_message = "Pool type should be 'dir'"
  }
}

run "plan_with_custom_project_name" {
  command = plan

  variables {
    project_name = "hardened"
  }

  assert {
    condition     = libvirt_network.secure.name == "hardened-secure-net"
    error_message = "Network name should use custom project_name"
  }

  assert {
    condition     = libvirt_pool.secure.name == "hardened-secure-pool"
    error_message = "Pool name should use custom project_name"
  }

  assert {
    condition     = libvirt_cloudinit_disk.secure.name == "hardened-cloudinit.iso"
    error_message = "Cloud-init disk name should use custom project_name"
  }
}
