# TF-204: Import & Migration Strategies — Variables

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "my-app"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.app_name))
    error_message = "app_name must be 3-32 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "app_version" {
  description = "Application version string"
  type        = string
  default     = "1.0.0"
}

variable "db_host" {
  description = "Database hostname"
  type        = string
  default     = "localhost"
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432

  validation {
    condition     = var.db_port >= 1024 && var.db_port <= 65535
    error_message = "db_port must be between 1024 and 65535."
  }
}

variable "services" {
  description = "List of service names to register"
  type        = list(string)
  default     = ["api", "worker", "scheduler"]
}