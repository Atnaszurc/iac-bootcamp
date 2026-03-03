# TF-303: Terraform Test Framework — Variables

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"

  validation {
    condition     = contains(["dev", "staging", "prod"], lower(var.environment))
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "services" {
  type = map(object({
    port    = number
    enabled = bool
  }))
  description = "Map of services to configure. Each service has a port and enabled flag."

  validation {
    condition     = length(var.services) > 0
    error_message = "At least one service must be defined."
  }

  validation {
    condition = alltrue([
      for name, svc in var.services : svc.port >= 1 && svc.port <= 65535
    ])
    error_message = "All service ports must be between 1 and 65535."
  }
}

variable "log_level" {
  type        = string
  description = "Log level for all services"
  default     = "info"

  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be one of: debug, info, warn, error."
  }
}

variable "enable_debug" {
  type        = bool
  description = "When true, creates an additional debug information file"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources"
  default     = {}
}