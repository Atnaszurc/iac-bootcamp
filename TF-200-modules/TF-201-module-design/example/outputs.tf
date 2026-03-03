# TF-201: Module Design — Root Module Outputs
# Module outputs are accessed via: module.<name>.<output_name>

# ─── Development environment outputs ───────────────────────────
output "dev_config_path" {
  description = "Path to the dev environment main config file"
  value       = module.app_dev.config_file_path
}

output "dev_env_config_path" {
  description = "Path to the dev environment-specific config file"
  value       = module.app_dev.env_config_file_path
}

output "dev_output_directory" {
  description = "Directory containing all dev config files"
  value       = module.app_dev.output_directory
}

output "dev_tags" {
  description = "Effective tags for the dev environment"
  value       = module.app_dev.effective_tags
}

# ─── Staging environment outputs ───────────────────────────────
output "staging_config_path" {
  description = "Path to the staging environment main config file"
  value       = module.app_staging.config_file_path
}

output "staging_output_directory" {
  description = "Directory containing all staging config files"
  value       = module.app_staging.output_directory
}

# ─── Production environment outputs ────────────────────────────
output "prod_config_path" {
  description = "Path to the prod environment main config file"
  value       = module.app_prod.config_file_path
}

output "prod_output_directory" {
  description = "Directory containing all prod config files"
  value       = module.app_prod.output_directory
}

output "prod_tags" {
  description = "Effective tags for the prod environment"
  value       = module.app_prod.effective_tags
}

# ─── Summary output ────────────────────────────────────────────
# Demonstrates collecting outputs from multiple module instances
output "all_config_directories" {
  description = "Map of environment name to output directory"
  value = {
    dev     = module.app_dev.output_directory
    staging = module.app_staging.output_directory
    prod    = module.app_prod.output_directory
  }
}