output "all_names" {
  description = "All server names (list)"
  value       = local.all_names
}

output "enabled_names" {
  description = "Only enabled server names (filtered list)"
  value       = local.enabled_names
}

output "name_to_role" {
  description = "Map of server name to role"
  value       = local.name_to_role
}

output "enabled_map" {
  description = "Map of enabled server name to role"
  value       = local.enabled_map
}

output "tag_strings" {
  description = "Tags as key=value strings"
  value       = local.tag_strings
}

output "prefixed_tags" {
  description = "Tags with environment prefix on keys"
  value       = local.prefixed_tags
}

output "display_strings" {
  description = "Human-readable server status strings"
  value       = local.display_strings
}