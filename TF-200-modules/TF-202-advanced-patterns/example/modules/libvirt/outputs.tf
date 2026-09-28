output "ip_address" {
  description = "IP address assigned to the VM by DHCP (known after apply)"
  value       = try(data.libvirt_domain_interface_addresses.this.interfaces[0].addrs[0].addr, null)
}

output "vm_name" {
  description = "Name of the created VM"
  value       = libvirt_domain.this.name
}