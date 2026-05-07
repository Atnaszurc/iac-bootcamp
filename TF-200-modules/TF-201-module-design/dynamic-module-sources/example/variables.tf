variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "use_local_development" {
  description = "Use local modules for development instead of remote"
  type        = bool
  default     = true
}

variable "enable_advanced_features" {
  description = "Enable advanced features module"
  type        = bool
  default     = false
}

variable "override_module_versions" {
  description = "Override module versions for testing"
  type        = map(string)
  default     = {}
}

variable "cloud_provider" {
  description = "Cloud provider (aws, azure, gcp)"
  type        = string
  default     = "aws"

  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "Cloud provider must be aws, azure, or gcp"
  }
}

variable "enable_canary_deployment" {
  description = "Enable canary deployment with beta module version"
  type        = bool
  default     = false
}

variable "tenant_id" {
  description = "Tenant identifier for multi-tenant configurations"
  type        = string
  default     = "default"
}

variable "ci_module_version" {
  description = "Module version from CI/CD pipeline"
  type        = string
  default     = ""
}

variable "ci_environment" {
  description = "Running in CI/CD environment"
  type        = bool
  default     = false
}