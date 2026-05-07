output "config_data" {
  description = "Configuration data"
  value       = terraform_data.config.input
}

output "config_json" {
  description = "Configuration as JSON string"
  value       = terraform_data.config_file.input
}

output "app_name" {
  description = "Application name"
  value       = var.app_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "version" {
  description = "Configuration version"
  value       = var.version_tag
}