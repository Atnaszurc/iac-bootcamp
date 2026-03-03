# TF-301 Supplement: Cross-Variable Validation (Terraform 1.9+)
# Demonstrates validation conditions that reference other variables

# ─────────────────────────────────────────────────────────────────────────────
# Core variables — validated independently first
# ─────────────────────────────────────────────────────────────────────────────

variable "environment" {
  type        = string
  description = "Deployment environment: dev, staging, or prod"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  type        = string
  description = "Project name used in resource naming"
  default     = "hashi-training"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,28}[a-z0-9]$", var.project_name))
    error_message = "Project name must be 3-30 characters, lowercase letters/numbers/hyphens, start with a letter."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Cross-variable validation: instance_count depends on environment
#
# Terraform 1.9+: validation blocks can reference other variables (var.environment)
# Before 1.9: this would cause an error — only self-reference was allowed
# ─────────────────────────────────────────────────────────────────────────────

variable "instance_count" {
  type        = number
  description = "Number of application instances to deploy"
  default     = 1

  validation {
    condition     = var.instance_count >= 1
    error_message = "Instance count must be at least 1."
  }

  validation {
    # Cross-variable: production requires at least 3 instances for high availability
    # Terraform 1.9+: references var.environment (a different variable)
    condition     = var.environment == "prod" ? var.instance_count >= 3 : var.instance_count >= 1
    error_message = "Production requires at least 3 instances for high availability; other environments require at least 1."
  }

  validation {
    condition     = var.instance_count <= 20
    error_message = "Instance count cannot exceed 20."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Cross-variable validation: disk_size_gb depends on environment
# ─────────────────────────────────────────────────────────────────────────────

variable "disk_size_gb" {
  type        = number
  description = "Root disk size in GB"
  default     = 20

  validation {
    # Cross-variable: production requires larger disks
    condition     = var.environment == "prod" ? var.disk_size_gb >= 50 : var.disk_size_gb >= 10
    error_message = "Production disks must be at least 50 GB; other environments at least 10 GB."
  }

  validation {
    condition     = var.disk_size_gb <= 2000
    error_message = "Disk size cannot exceed 2000 GB."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Cross-variable validation: backup settings must be consistent
# ─────────────────────────────────────────────────────────────────────────────

variable "enable_backups" {
  type        = bool
  description = "Whether to enable automated backups"
  default     = false
}

variable "backup_retention_days" {
  type        = number
  description = "Number of days to retain backups (ignored when enable_backups = false)"
  default     = 0

  validation {
    # Cross-variable: if backups are enabled, retention must be meaningful
    condition     = var.enable_backups ? var.backup_retention_days >= 7 : var.backup_retention_days >= 0
    error_message = "When backups are enabled, retention must be at least 7 days."
  }

  validation {
    condition     = var.backup_retention_days <= 365
    error_message = "Backup retention cannot exceed 365 days."
  }
}

variable "require_backups_in_prod" {
  type        = bool
  description = "Internal flag — set to true to enforce backup requirement in prod (demo purposes)"
  default     = true
}