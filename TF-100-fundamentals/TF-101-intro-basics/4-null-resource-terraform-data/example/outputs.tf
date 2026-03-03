output "deployment_info" {
  description = "Deployment metadata stored in terraform_data"
  value       = terraform_data.deployment_info.output
}

output "config_file_path" {
  description = "Path to the generated config file"
  value       = local_file.app_config.filename
}