output "basic_config" {
  description = "Basic configuration module output"
  value       = module.basic_config.config_data
}

output "versioned_config" {
  description = "Versioned configuration module output"
  value       = module.versioned_config.config_data
}

output "conditional_config" {
  description = "Conditional configuration module output"
  value       = module.conditional_config.config_data
}

output "registry_config" {
  description = "Registry-based configuration module output"
  value       = module.registry_config.config_data
}

output "matrix_config" {
  description = "Matrix-based configuration module output"
  value       = module.matrix_config.config_data
}

output "feature_config" {
  description = "Feature flag configuration module output"
  value       = module.feature_config.config_data
}

output "override_config" {
  description = "Override configuration module output"
  value       = module.override_config.config_data
}

output "cloud_config" {
  description = "Cloud-specific configuration module output"
  value       = module.cloud_config.config_data
}

output "canary_config" {
  description = "Canary deployment configuration module output"
  value       = module.canary_config.config_data
}

output "tenant_config" {
  description = "Tenant-specific configuration module output"
  value       = module.tenant_config.config_data
}

output "pipeline_config" {
  description = "CI/CD pipeline configuration module output"
  value       = module.pipeline_config.config_data
}

output "environment_versions" {
  description = "Environment-specific module versions"
  value       = local.environment_versions
}

output "version_matrix" {
  description = "Complete version matrix for all environments"
  value       = local.version_matrix
}

output "module_registry" {
  description = "Central module registry"
  value = {
    for k, v in local.module_registry : k => {
      source      = v.source
      version     = v.version
      description = v.description
    }
  }
}