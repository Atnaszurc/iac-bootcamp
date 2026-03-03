# TF-201: Module Design — Child Module Variables (Inputs)

variable "app_name" {
  type        = string
  description = "Name of the application"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.app_name))
    error_message = "app_name must be 3-32 lowercase alphanumeric characters or hyphens, starting with a letter."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "port" {
  type        = number
  description = "Application port number"
  default     = 8080

  validation {
    condition     = var.port >= 1024 && var.port <= 65535
    error_message = "port must be between 1024 and 65535."
  }
}

variable "log_level" {
  type        = string
  description = "Application log level"
  default     = "info"

  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "log_level must be one of: debug, info, warn, error."
  }
}

variable "debug_mode" {
  type        = bool
  description = "Enable debug mode"
  default     = false
}

variable "base_dir" {
  type        = string
  description = "Base directory for output files"
  default     = "output"
}

variable "env_overrides" {
  type        = map(string)
  description = "Environment-specific configuration overrides"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}