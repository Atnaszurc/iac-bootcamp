terraform {
  required_version = ">= 1.15.0"
}

# Demonstrate using both new and deprecated variables
resource "local_file" "config_new" {
  content  = <<-EOT
    Configuration using NEW variables:
    Instance Type: ${local.effective_instance_type}
    Environment: ${local.effective_environment}
    Monitoring: ${local.effective_monitoring}
    
    Generated at: ${timestamp()}
  EOT
  filename = "${path.module}/config_new.txt"
}

# Show what happens when using deprecated variables directly
resource "local_file" "config_deprecated" {
  content  = <<-EOT
    Configuration using DEPRECATED variables (will show warnings):
    Old Instance Type: ${var.old_instance_type}
    Env: ${var.env}
    Monitoring: ${var.monitoring}
    
    ⚠️  These variables are deprecated!
    Please migrate to: instance_type, environment, enable_monitoring
  EOT
  filename = "${path.module}/config_deprecated.txt"
}

# Best practice: Use effective values that handle both old and new
resource "local_file" "config_effective" {
  content  = <<-EOT
    Effective Configuration (handles both old and new):
    Instance Type: ${local.effective_instance_type}
    Environment: ${local.effective_environment}
    Monitoring Enabled: ${local.effective_monitoring}
    
    This configuration works with both old and new variable names,
    allowing for gradual migration.
  EOT
  filename = "${path.module}/config_effective.txt"
}

# Example: Conditional resource based on effective values
resource "local_file" "monitoring_config" {
  count = local.effective_monitoring ? 1 : 0

  content  = <<-EOT
    Monitoring Configuration
    Environment: ${local.effective_environment}
    Instance Type: ${local.effective_instance_type}
    Monitoring Enabled: true
  EOT
  filename = "${path.module}/monitoring.txt"
}