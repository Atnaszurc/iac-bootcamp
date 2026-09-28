# Outputs demonstrating the deprecated attribute (Terraform 1.15+)

# === NEW (PREFERRED) OUTPUTS ===

output "instance_configuration" {
  description = "Complete instance configuration (preferred output)"
  value = {
    type        = local.effective_instance_type
    environment = local.effective_environment
    monitoring  = local.effective_monitoring
  }
}

output "environment_name" {
  description = "Environment name (preferred output)"
  value       = local.effective_environment
}

output "monitoring_status" {
  description = "Monitoring enabled status"
  value       = local.effective_monitoring
}

# === DEPRECATED OUTPUTS (for backward compatibility) ===
# Note: The 'deprecated' attribute only works in child modules, not root modules.
# In a real scenario, these would be in a module with the deprecated attribute.
# For this example, we show them with deprecation notices in descriptions only.

output "old_config" {
  description = "⚠️ DEPRECATED: Use 'instance_configuration' instead. This output will be removed in v2.0.0. The new output provides structured data instead of a concatenated string."
  value       = "${local.effective_instance_type}-${local.effective_environment}"
}

output "env_name" {
  description = "⚠️ DEPRECATED: Use 'environment_name' instead. This output will be removed in v2.0.0 for naming consistency."
  value       = local.effective_environment
}

output "instance_type_value" {
  description = "⚠️ DEPRECATED: Use 'instance_configuration.type' instead. Direct instance type output is deprecated. Access it from the structured 'instance_configuration' output."
  value       = local.effective_instance_type
}

# === MIGRATION HELPER OUTPUT ===

output "migration_status" {
  description = "Shows which variables are being used (old vs new)"
  value = {
    using_new_instance_type = var.instance_type != "t3.micro"
    using_new_environment   = var.environment != "development"
    using_new_monitoring    = var.enable_monitoring != false

    using_old_instance_type = var.old_instance_type != "t2.micro"
    using_old_environment   = var.env != "dev"
    using_old_monitoring    = var.monitoring != false

    migration_complete = (
      var.instance_type != "t3.micro" &&
      var.environment != "development" &&
      var.old_instance_type == "t2.micro" &&
      var.env == "dev"
    )
  }
}