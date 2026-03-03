# Non-sensitive output — shows value normally
output "app_name" {
  description = "Application name (not sensitive)"
  value       = var.app_name
}

# Explicitly sensitive output — shows <sensitive> in terraform output
output "db_password" {
  description = "Database password — redacted in output"
  value       = var.db_password
  sensitive   = true
}

# Automatically sensitive — contains a sensitive variable
# Terraform requires sensitive = true here because var.db_password is sensitive
output "connection_string" {
  description = "Full DB connection string (sensitive — contains password)"
  value       = "postgresql://admin:${var.db_password}@${var.db_host}/mydb"
  sensitive   = true
}

# nonsensitive() — safe to display because db_host is not actually secret
output "db_host_display" {
  description = "Database hostname (safe to display)"
  value       = var.db_host
  # db_host is not marked sensitive, so no nonsensitive() needed here
}

# nonsensitive() with substr — show only first 4 chars of API key for identification
output "api_key_prefix" {
  description = "First 4 characters of API key (safe to display for identification)"
  value       = nonsensitive(substr(var.api_key, 0, 4))
}