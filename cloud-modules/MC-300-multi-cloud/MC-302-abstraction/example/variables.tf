# MC-302: Provider Abstraction Patterns
# Variables for cloud-agnostic module demonstration

variable "project_name" {
  description = "Project name used across all cloud resources"
  type        = string
  default     = "mc302-demo"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens only."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be 'dev', 'staging', or 'prod'."
  }
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# ---------------------------------------------------------------------------
# Abstraction: t-shirt size → cloud-specific instance type mapping
# This is the core of the MC-302 abstraction pattern
# ---------------------------------------------------------------------------

variable "vm_size" {
  description = "VM size class (small, medium, large) - abstracted from cloud-specific types"
  type        = string
  default     = "small"

  validation {
    condition     = contains(["small", "medium", "large"], var.vm_size)
    error_message = "VM size must be 'small', 'medium', or 'large'."
  }
}

variable "aws_public_key" {
  description = "SSH public key for AWS EC2 instances"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDY5O6Vlecaw4jVcv15DNFm5VJYtWcjKPpentQHWNcuFCUl/7TAR+3B418mWGZhgDbExH+ipVyq+Bz9hS5wugYjSsaiMPa5X2wjKSCMOwUWnluzUgSFnHhyj45NWFI0S7atbU9sqGE5tqXEh1tMqkIkp1tWJexKMd4Q8M4nCJVMOtcG2CWuh7BUdJLPcMzOaYGgSNxaOvabpT8+cMoVINrIVd1UTwKi7h5WthKID72drCt2lHG1pzQnPK6DkzjTbGlul/19Lm1d8DjMAg7GMXAEaa7dbWIt4LrZCNCv/0oZ0XQlxWxl1INgKEuOIsLjf4geafwqiEGtZdcZFFjPIplt test@example.com"
}

variable "azure_admin_public_key" {
  description = "SSH public key for Azure Linux VMs"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDY5O6Vlecaw4jVcv15DNFm5VJYtWcjKPpentQHWNcuFCUl/7TAR+3B418mWGZhgDbExH+ipVyq+Bz9hS5wugYjSsaiMPa5X2wjKSCMOwUWnluzUgSFnHhyj45NWFI0S7atbU9sqGE5tqXEh1tMqkIkp1tWJexKMd4Q8M4nCJVMOtcG2CWuh7BUdJLPcMzOaYGgSNxaOvabpT8+cMoVINrIVd1UTwKi7h5WthKID72drCt2lHG1pzQnPK6DkzjTbGlul/19Lm1d8DjMAg7GMXAEaa7dbWIt4LrZCNCv/0oZ0XQlxWxl1INgKEuOIsLjf4geafwqiEGtZdcZFFjPIplt test@example.com"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}