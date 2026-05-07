# Outputs demonstrating convert() function results

output "basic_conversions" {
  description = "Basic type conversion examples"
  value = {
    port_number    = local.port_number
    count_string   = local.count_string
    enabled_bool   = local.enabled_bool
    tags_set       = local.tags_set
  }
}

output "typed_config" {
  description = "Object with properly typed fields"
  value       = local.typed_config
}

output "calculated_values" {
  description = "Values calculated using converted types"
  value = {
    total_capacity = local.total_capacity
    port_range     = local.port_range
    total_memory   = local.total_memory
    total_disk     = local.total_disk
  }
}

output "environment_configs" {
  description = "Typed environment configurations"
  value       = local.typed_environments
}

output "server_info" {
  description = "Parsed and typed server information"
  value = {
    basic_info = {
      id      = local.server_info.server_id
      name    = local.server_info.server_name
      running = local.server_info.is_running
    }
    resources = {
      cpu_count = local.server_info.cpu_count
      memory_gb = local.server_info.memory_gb
      disk_gb   = local.server_info.disk_gb
    }
    calculated = {
      uptime_days      = local.uptime_days
      total_storage_mb = local.total_storage_mb
      memory_per_cpu   = local.memory_per_cpu
    }
    tags           = local.server_info.tags
    is_production  = local.is_production
  }
}

output "app_configuration" {
  description = "Typed application configuration"
  value = {
    application     = local.app_config.application
    database        = local.app_config.database
    connection_string = local.connection_string
    total_workers   = local.total_workers
  }
}

output "validated_user" {
  description = "Validated user input with proper types"
  value = {
    user_info = {
      username = local.validated_user.username
      age      = local.validated_user.age
      active   = local.validated_user.active
    }
    roles    = local.validated_user.roles
    metadata = local.validated_user.metadata
    checks = {
      is_admin = local.is_admin
      is_adult = local.is_adult
    }
  }
}

output "conversion_summary" {
  description = "Summary of all conversions performed"
  value = {
    basic_conversions_count    = 4
    object_conversions_count   = 2
    list_conversions_count     = 2
    map_conversions_count      = 2
    complex_structures_count   = 1
    api_responses_parsed       = 1
    configs_processed          = 1
    validations_performed      = 1
    
    total_conversions = 14
    
    types_demonstrated = [
      "string → number",
      "number → string",
      "string → bool",
      "list → set",
      "map(string) → map(number)",
      "list(string) → list(number)",
      "any → object(...)",
      "nested objects",
      "complex structures"
    ]
  }
}