variable "app_name" {
  type        = string
  description = "Application name (not sensitive)"
  default     = "hashi-training"
}

variable "db_password" {
  type        = string
  description = "Database password (sensitive) — never appears in plan/apply output"
  sensitive   = true
  default     = "super-secret-password-123"

  validation {
    condition     = length(var.db_password) >= 12
    error_message = "Password must be at least 12 characters."
    # Note: do NOT include the actual value in error messages for sensitive variables
  }
}

variable "api_key" {
  type        = string
  description = "API key for external service (sensitive)"
  sensitive   = true
  default     = "abcd1234efgh5678ijkl9012"

  validation {
    condition     = length(var.api_key) >= 20
    error_message = "API key must be at least 20 characters."
  }
}

variable "db_host" {
  type        = string
  description = "Database hostname — not actually secret, but grouped with sensitive vars"
  default     = "db.internal.example.com"
}