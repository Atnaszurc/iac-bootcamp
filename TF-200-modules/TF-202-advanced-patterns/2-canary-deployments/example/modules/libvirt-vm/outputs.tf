# =============================================================================
# modules/libvirt-vm/outputs.tf
# =============================================================================

output "vm_names" {
  description = "Names of all VM domains in this pool."
  value       = libvirt_domain.vm[*].name
}

output "vm_ips" {
  description = "IP address of each VM (null until DHCP has handed one out)."
  value = [
    for d in data.libvirt_domain_interface_addresses.vm :
    try(d.interfaces[0].addrs[0].addr, null)
  ]
}

output "generation" {
  description = "Current generation suffix. Changes when the pool is rolled."
  value       = random_id.generation.hex
}

output "pool_name" {
  description = "The deployment pool name (echoed back for reference)."
  value       = var.pool_name
}
