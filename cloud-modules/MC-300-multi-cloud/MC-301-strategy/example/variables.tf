# MC-301: Multi-Cloud Strategy & Design
# Variables for multi-provider configuration example

variable "project_name" {
  description = "Project name used across all cloud resources"
  type        = string
  default     = "mc301-demo"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens only."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be 'dev', 'staging', or 'prod'."
  }
}

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "azure_region" {
  description = "Primary Azure region"
  type        = string
  default     = "West Europe"
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "team_name" {
  description = "Team responsible for these resources"
  type        = string
  default     = "platform-team"
}

variable "cost_center" {
  description = "Cost center for billing allocation (format: CC-XXXX)"
  type        = string
  default     = "CC-0001"

  validation {
    condition     = can(regex("^CC-[0-9]{4}$", var.cost_center))
    error_message = "Cost center must be in format CC-XXXX (e.g., CC-0001)."
  }
}

# Environment-based sizing configuration
# Demonstrates workspace-driven configuration pattern from MC-301
variable "environment_config" {
  description = "Per-environment resource sizing configuration"
  type = map(object({
    aws_instance_type = string
    azure_vm_size     = string
    replicas          = number
  }))

  default = {
    dev = {
      aws_instance_type = "t3.micro"
      azure_vm_size     = "Standard_B1s"
      replicas          = 1
    }
    staging = {
      aws_instance_type = "t3.small"
      azure_vm_size     = "Standard_B2s"
      replicas          = 2
    }
    prod = {
      aws_instance_type = "t3.medium"
      azure_vm_size     = "Standard_D2s_v3"
      replicas          = 3
    }
  }
}