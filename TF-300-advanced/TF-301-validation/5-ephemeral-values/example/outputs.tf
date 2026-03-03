# TF-301 Section 5: Ephemeral Values — Outputs
#
# Demonstrates the difference between ephemeral and regular outputs.

# ─────────────────────────────────────────────────────────────────────────────
# EPHEMERAL OUTPUT (Terraform 1.10+)
#
# This output references an ephemeral local (which references var.db_password).
# It MUST be marked ephemeral = true, otherwise Terraform will error.
#
# Ephemeral outputs:
# - Are NOT stored in state
# - Cannot be read with 'terraform output'
# - Can only be consumed by calling modules in ephemeral contexts
# ─────────────────────────────────────────────────────────────────────────────

output "connection_string" {
  value       = local.connection_string
  description = "Database connection string — ephemeral, never stored in state"
  ephemeral   = true  # Required because local.connection_string is ephemeral
}

# ─────────────────────────────────────────────────────────────────────────────
# REGULAR OUTPUTS (stored in state, readable via 'terraform output')
# ─────────────────────────────────────────────────────────────────────────────

output "db_endpoint" {
  value       = local.db_endpoint
  description = "Database endpoint (host/name) — safe to store in state"
}

output "app_name" {
  value       = var.app_name
  description = "Application name"
}

output "environment" {
  value       = var.environment
  description = "Deployment environment"
}

output "api_token_provided" {
  value       = local.api_token_provided
  description = "Whether an API token was provided (boolean, not the token itself)"
  # This is a boolean — safe to store in state
  # The actual token value is never stored thanks to ephemeralasnull()
}

output "config_file_path" {
  value       = local_file.app_config.filename
  description = "Path to the generated application config file"
}

# ─────────────────────────────────────────────────────────────────────────────
# WHAT YOU CANNOT DO — these would cause errors:
# ─────────────────────────────────────────────────────────────────────────────

# ❌ ERROR: Cannot use ephemeral value in non-ephemeral output
# output "bad_password_output" {
#   value = var.db_password  # var.db_password is ephemeral
#   # Error: "Ephemeral value not allowed"
#   # Fix: add ephemeral = true, or use ephemeralasnull()
# }

# ❌ ERROR: Cannot use ephemeral local in non-ephemeral output
# output "bad_connection_string" {
#   value = local.connection_string  # ephemeral because it uses var.db_password
#   # Error: "Ephemeral value not allowed"
# }

# ✅ CORRECT: Use ephemeralasnull() to get a non-ephemeral null check
# output "password_was_set" {
#   value = ephemeralasnull(var.db_password) != null  # Returns true/false, not the password
# }