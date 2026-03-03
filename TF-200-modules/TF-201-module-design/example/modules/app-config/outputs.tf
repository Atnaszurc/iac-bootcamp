# TF-201: Module Design — Child Module Outputs

output "app_name" {
  description = "The application name"
  value       = var.app_name
}

output "config_file_path" {
  description = "Path to the main application config file"
  value       = local_file.app_config.filename
}

output "env_config_file_path" {
  description = "Path to the environment-specific config file"
  value       = local_file.env_overrides.filename
}

output "metadata_file_path" {
  description = "Path to the metadata JSON file"
  value       = local_file.metadata.filename
}

output "output_directory" {
  description = "Directory where all config files are written"
  value       = local.output_dir
}

output "effective_tags" {
  description = "All tags applied to this module's resources"
  value       = local.all_tags
}