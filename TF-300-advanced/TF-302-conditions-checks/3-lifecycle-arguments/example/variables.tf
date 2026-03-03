variable "app_name" {
  type        = string
  description = "Application name"
  default     = "hashi-training"
}

variable "config_version" {
  type        = string
  description = "Configuration version — changing this triggers replacement of app_config"
  default     = "v1"

  validation {
    condition     = can(regex("^v[0-9]+$", var.config_version))
    error_message = "Config version must be in format 'v<number>' (e.g., v1, v2, v10)."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}