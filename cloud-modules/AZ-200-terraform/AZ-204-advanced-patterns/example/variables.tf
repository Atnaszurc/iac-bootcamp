variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "az204"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project_name))
    error_message = "project_name must be 3-20 lowercase alphanumeric characters or hyphens."
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

variable "vm_sku" {
  description = "VM SKU for the scale set instances"
  type        = string
  default     = "Standard_B1s"
}

variable "instance_count" {
  description = "Initial number of VM instances in the scale set"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 100
    error_message = "instance_count must be between 1 and 100."
  }
}

variable "min_instances" {
  description = "Minimum number of instances for autoscaling"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances for autoscaling"
  type        = number
  default     = 5
}

variable "admin_username" {
  description = "Admin username for VM instances"
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "SSH public key for admin access to VM instances"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR block allowed SSH access to instances"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be a valid CIDR block."
  }
}