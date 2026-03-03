# =============================================================================
# modules/libvirt-vm/outputs.tf
# =============================================================================

output "vm_names" {
  description = "Names of all VM domains created in this pool."
  value       = libvirt_domain.vm[*].name
}

output "vm_ids" {
  description = "IDs of all VM domains created in this pool."
  value       = libvirt_domain.vm[*].id
}

output "pool_name" {
  description = "The deployment pool name (echoed back for reference)."
  value       = var.pool_name
}

output "vm_count" {
  description = "Number of VMs in this pool."
  value       = var.vm_count
}