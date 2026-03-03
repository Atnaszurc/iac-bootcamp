# TF-301 Section 5: Ephemeral Values
# Variables — mix of ephemeral and regular variables

# ─────────────────────────────────────────────────────────────────────────────
# EPHEMERAL VARIABLES (Terraform 1.10+)
# These values are NEVER written to state, plan files, or logs.
# They exist only in memory during the Terraform operation.
# ─────────────────────────────────────────────────────────────────────────────

variable "db_password" {
  type        = string
  description = "Database password — ephemeral, never stored in state"
  ephemeral   = true  # Terraform 1.10+

  # Note: ephemeral variables cannot have validation blocks that reference
  # non-ephemeral values, but basic validation is allowed
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters."
  }
}

variable "api_token" {
  type        = string
  description = "API token for external service — ephemeral, never stored in state"
  ephemeral   = true  # Terraform 1.10+
  default     = null  # Optional — may not always be provided
}

# ─────────────────────────────────────────────────────────────────────────────
# REGULAR VARIABLES (stored in state as normal)
# ─────────────────────────────────────────────────────────────────────────────

variable "db_host" {
  type        = string
  description = "Database hostname — safe to store in state"
  default     = "db.example.internal"
}

variable "db_name" {
  type        = string
  description = "Database name — safe to store in state"
  default     = "appdb"
}

variable "app_name" {
  type        = string
  description = "Application name — safe to store in state"
  default     = "my-app"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.app_name))
    error_message = "App name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}