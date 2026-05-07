# Terraform 1.15+ Deprecated Attribute Example
# This example demonstrates how to use the deprecated attribute for variables

# === NEW (PREFERRED) VARIABLES ===

variable "instance_type" {
  description = "EC2 instance type (preferred variable name)"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Instance type must be t3.micro, t3.small, or t3.medium."
  }
}

variable "environment" {
  description = "Environment name (preferred variable name)"
  type        = string
  default     = "development"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "enable_monitoring" {
  description = "Enable monitoring for resources"
  type        = bool
  default     = false
}

# === DEPRECATED VARIABLES (for backward compatibility) ===
# Note: The 'deprecated' attribute only works in child modules, not root modules.
# In a real scenario, these would be in a module with the deprecated attribute.
# For this example, we show them with deprecation notices in descriptions only.

variable "old_instance_type" {
  description = "⚠️ DEPRECATED: Use 'instance_type' instead. This variable will be removed in v2.0.0. The new variable uses t3 instances by default."
  type        = string
  default     = "t2.micro"
}

variable "env" {
  description = "⚠️ DEPRECATED: Use 'environment' instead. The 'env' variable is deprecated and will be removed in v2.0.0. Use full environment names (development, staging, production)."
  type        = string
  default     = "dev"
}

variable "monitoring" {
  description = "⚠️ DEPRECATED: Use 'enable_monitoring' instead. This variable will be removed in v2.0.0 for naming consistency."
  type        = bool
  default     = false
}

# === BACKWARD COMPATIBILITY LOGIC ===

locals {
  # Use new variables if they differ from defaults, otherwise use old variables
  # This allows gradual migration
  effective_instance_type = var.instance_type != "t3.micro" ? var.instance_type : (
    var.old_instance_type != "t2.micro" ? var.old_instance_type : var.instance_type
  )

  effective_environment = var.environment != "development" ? var.environment : (
    var.env != "dev" ? var.env : var.environment
  )

  effective_monitoring = var.enable_monitoring != false ? var.enable_monitoring : var.monitoring
}