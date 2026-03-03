output "ip_address" {
  description = "IP address assigned to the VM by DHCP (computed at apply time)"
  value       = "IP will be assigned by DHCP at apply time"
}

output "vm_name" {
  description = "Name of the created VM"
  value       = libvirt_domain.this.name
}

output "network_id" {
  description = "ID of the VM's network"
  value       = libvirt_network.this.id
}