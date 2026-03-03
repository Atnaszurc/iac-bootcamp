# TF-204: Import & Migration Strategies — Outputs

output "app_config_path" {
  description = "Path to the application config file"
  value       = local_file.app_config.filename
}

output "database_config_path" {
  description = "Path to the database config file"
  value       = local_file.database_config.filename
}

output "service_registry_path" {
  description = "Path to the service registry JSON file"
  value       = local_file.service_registry.filename
}

output "all_managed_files" {
  description = "Map of config name to file path — all files now managed by Terraform"
  value = {
    app_config      = local_file.app_config.filename
    database_config = local_file.database_config.filename
    service_registry = local_file.service_registry.filename
  }
}

output "import_ids" {
  description = "The IDs that would be used in import blocks for each resource"
  value = {
    app_config      = local_file.app_config.id
    database_config = local_file.database_config.id
    service_registry = local_file.service_registry.id
  }
}