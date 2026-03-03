# These outputs are what the compute configuration will read
# via terraform_remote_state

output "network_id" {
  description = "ID of the main network — consumed by compute layer"
  value       = var.network_id
}

output "network_name" {
  description = "Name of the main network"
  value       = var.network_name
}

output "network_cidr" {
  description = "CIDR block of the main network — consumed by compute layer"
  value       = var.network_cidr
}