variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "my-app"
}

variable "app_version" {
  description = "Version of the application"
  type        = string
  default     = "1.0.0"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "enabled" {
  description = "Whether the application is enabled"
  type        = bool
  default     = true
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10"
  }
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}