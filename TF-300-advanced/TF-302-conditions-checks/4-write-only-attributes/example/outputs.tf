# TF-302 Section 4: Write-Only Attributes — Outputs

# ─────────────────────────────────────────────────────────────────────────────
# SAFE OUTPUTS — these are stored in state and readable via 'terraform output'
# ─────────────────────────────────────────────────────────────────────────────

output "db_name" {
  value       = var.db_name
  description = "Database name — safe to output"
}

output "db_host" {
  value       = var.db_host
  description = "Database host — safe to output"
}

output "environment" {
  value       = var.environment
  description = "Deployment environment"
}

output "password_version" {
  value       = var.db_password_version
  description = "Current password version — stored in state, used to track rotations"
}

output "metadata_file" {
  value       = local_file.db_metadata.filename
  description = "Path to the generated metadata file"
}

# ─────────────────────────────────────────────────────────────────────────────
# WHAT YOU CANNOT OUTPUT:
# ─────────────────────────────────────────────────────────────────────────────

# ❌ ERROR: Cannot use ephemeral value in non-ephemeral output
# output "db_password" {
#   value = var.db_password  # ephemeral — cannot be in non-ephemeral output
# }

# ✅ CORRECT: Mark as ephemeral if you need to pass it to a calling module
# output "db_password_ephemeral" {
#   value     = var.db_password
#   ephemeral = true  # Can only be consumed by ephemeral contexts in calling module
# }

# ─────────────────────────────────────────────────────────────────────────────
# AFTER APPLY — verify the write-only pattern worked:
#
# Run: terraform output
# You will see: db_name, db_host, environment, password_version
# You will NOT see: db_password (it was never stored)
#
# Run: cat terraform.tfstate | grep -i password
# You will see: "password_version" = "1"
# You will NOT see: the actual password value
# ─────────────────────────────────────────────────────────────────────────────