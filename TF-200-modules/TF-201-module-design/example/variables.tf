# TF-201: Module Design — Root Module Variables
# These are the inputs to the root module (the caller).
# The root module passes these down into child module instances.

variable "app_name" {
  description = "Name of the application (used across all environments)"
  type        = string
  default     = "my-app"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.app_name))
    error_message = "app_name must be 3-32 lowercase alphanumeric characters or hyphens, starting and ending with a letter or digit."
  }
}

variable "dev_port" {
  description = "Port for the development environment"
  type        = number
  default     = 8080

  validation {
    condition     = var.dev_port >= 1024 && var.dev_port <= 65535
    error_message = "dev_port must be between 1024 and 65535."
  }
}

variable "staging_port" {
  description = "Port for the staging environment"
  type        = number
  default     = 8081

  validation {
    condition     = var.staging_port >= 1024 && var.staging_port <= 65535
    error_message = "staging_port must be between 1024 and 65535."
  }
}

variable "prod_port" {
  description = "Port for the production environment"
  type        = number
  default     = 8443

  validation {
    condition     = var.prod_port >= 1024 && var.prod_port <= 65535
    error_message = "prod_port must be between 1024 and 65535."
  }
}

variable "common_tags" {
  description = "Tags applied to all module instances (merged with environment-specific tags)"
  type        = map(string)
  default = {
    Project   = "tf-201-demo"
    ManagedBy = "terraform"
    Course    = "TF-201"
  }
}