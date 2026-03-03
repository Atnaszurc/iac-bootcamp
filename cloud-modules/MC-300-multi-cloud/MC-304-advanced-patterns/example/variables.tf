# MC-304: Advanced Multi-Cloud Patterns
# Variables for observability, DR, and cost optimization example

variable "project_name" {
  description = "Project name used across all cloud resources"
  type        = string
  default     = "mc304-demo"

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
  description = "AWS region for primary resources"
  type        = string
  default     = "us-east-1"
}

variable "azure_region" {
  description = "Azure region for primary resources"
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
    error_message = "Cost center must be in format CC-XXXX."
  }
}

variable "alert_email" {
  description = "Email address for operational alerts from both clouds"
  type        = string
  default     = "ops-team@example.com"

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.alert_email))
    error_message = "Alert email must be a valid email address."
  }
}

variable "domain_name" {
  description = "Public domain name for DNS failover routing"
  type        = string
  default     = "example.com"
}

variable "log_retention_days" {
  description = "Number of days to retain logs in both clouds"
  type        = number
  default     = 30

  validation {
    condition     = contains([7, 14, 30, 60, 90, 180, 365], var.log_retention_days)
    error_message = "Log retention must be 7, 14, 30, 60, 90, 180, or 365 days."
  }
}

variable "cpu_alert_threshold" {
  description = "CPU utilization percentage threshold for alerts (both clouds)"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_alert_threshold >= 1 && var.cpu_alert_threshold <= 100
    error_message = "CPU alert threshold must be between 1 and 100."
  }
}

# ---------------------------------------------------------------------------
# Environment-based sizing (from MC-304 cost optimization pattern)
# ---------------------------------------------------------------------------

variable "environment_sizing" {
  description = "Resource sizing per environment for cost optimization"
  type = map(object({
    aws_instance_type = string
    azure_vm_size     = string
    min_instances     = number
    max_instances     = number
  }))

  default = {
    dev = {
      aws_instance_type = "t3.micro"
      azure_vm_size     = "Standard_B1s"
      min_instances     = 1
      max_instances     = 2
    }
    staging = {
      aws_instance_type = "t3.small"
      azure_vm_size     = "Standard_B2s"
      min_instances     = 1
      max_instances     = 4
    }
    prod = {
      aws_instance_type = "t3.medium"
      azure_vm_size     = "Standard_D2s_v3"
      min_instances     = 2
      max_instances     = 10
    }
  }
}