# TF-302 Section 4: Write-Only Attributes
# Variables — demonstrates ephemeral + version pattern

# ─────────────────────────────────────────────────────────────────────────────
# EPHEMERAL VARIABLE — the secret itself
# Never stored in state or plan files (Terraform 1.10+)
# ─────────────────────────────────────────────────────────────────────────────

variable "db_password" {
  type        = string
  description = "Database password — ephemeral, never stored in state"
  ephemeral   = true  # Terraform 1.10+

  validation {
    condition     = length(var.db_password) >= 12
    error_message = "Database password must be at least 12 characters."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# VERSION VARIABLE — tracks when the secret was last rotated
# Stored in state — increment to trigger password rotation
# ─────────────────────────────────────────────────────────────────────────────

variable "db_password_version" {
  type        = number
  description = "Increment this to trigger a password rotation (stored in state)"
  default     = 1

  validation {
    condition     = var.db_password_version >= 1
    error_message = "Password version must be at least 1."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# REGULAR VARIABLES — safe to store in state
# ─────────────────────────────────────────────────────────────────────────────

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "appdb"
}

variable "db_host" {
  type        = string
  description = "Database hostname"
  default     = "db.example.internal"
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