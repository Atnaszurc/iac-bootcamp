output "vm_name" {
  description = "Name of the deployed VM"
  value       = var.vm_name
}

output "vm_config_path" {
  description = "Path to the generated VM config file"
  value       = local_file.vm_config.filename
}

output "network_id_used" {
  description = "Network ID sourced from networking layer (demonstrates remote state sharing)"
  value       = data.terraform_remote_state.networking.outputs.network_id
}