# Inputs every deployment sets in deployments.tfdeploy.hcl

variable "environment" {
  type        = string
  description = "dev, staging or prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "owner" {
  type        = string
  description = "Team that owns this deployment"
}

variable "replicas" {
  type        = number
  description = "How many app instances this deployment describes"
  default     = 1
}
