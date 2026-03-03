variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project_name" {
  description = "Project name used as prefix for all resources (lowercase, no hyphens for storage account)"
  type        = string
  default     = "az203"

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.project_name))
    error_message = "project_name must be 3-10 lowercase alphanumeric characters (storage account naming constraint)."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "West Europe"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "disk_size_gb" {
  description = "Size of the managed data disk in GB"
  type        = number
  default     = 32

  validation {
    condition     = var.disk_size_gb >= 1 && var.disk_size_gb <= 32767
    error_message = "disk_size_gb must be between 1 and 32767."
  }
}