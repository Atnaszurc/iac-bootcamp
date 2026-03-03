output "vm_name" {
  value       = libvirt_domain.vm.name
  description = "Name of the virtual machine domain"
}

output "network_name" {
  value       = libvirt_network.main.name
  description = "Name of the libvirt network"
}

output "pool_name" {
  value       = libvirt_pool.main.name
  description = "Name of the libvirt storage pool"
}