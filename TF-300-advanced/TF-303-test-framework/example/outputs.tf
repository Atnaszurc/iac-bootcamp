# TF-303: Terraform Test Framework — Outputs

output "environment" {
  description = "The normalised (lowercase) environment name"
  value       = local.environment
}

output "service_count" {
  description = "Total number of services defined"
  value       = length(var.services)
}

output "enabled_service_count" {
  description = "Number of enabled services"
  value       = length(local.enabled_services)
}

output "enabled_service_names" {
  description = "List of enabled service names"
  value       = sort(keys(local.enabled_services))
}

output "config_file_paths" {
  description = "Map of service name → config file path"
  value = {
    for name, file in local_file.service_config : name => file.filename
  }
}

output "summary_file_path" {
  description = "Path to the summary file"
  value       = local_file.summary.filename
}

output "debug_enabled" {
  description = "Whether debug mode is enabled"
  value       = var.enable_debug
}

output "debug_file_path" {
  description = "Path to the debug file (null when debug is disabled)"
  value       = var.enable_debug ? local_file.debug_info[0].filename : null
}

output "common_tags" {
  description = "Tags applied to all resources"
  value       = local.common_tags
}