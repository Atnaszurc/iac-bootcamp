variable "password_version" {
  description = "Bump to rotate the captured password"
  type        = number
  default     = 1
}

variable "password_length" {
  description = "Length of the generated password"
  type        = number
  default     = 24

  validation {
    condition     = var.password_length >= 16
    error_message = "Password must be at least 16 characters."
  }
}

variable "db_user" {
  description = "Database user written next to the password"
  type        = string
  default     = "app"
}
