output "enabled_servers" {
  description = "Map of enabled servers parsed from servers.json"
  value       = local.enabled_servers
}

output "disabled_server_count" {
  description = "Number of servers that are disabled in the config"
  value       = length(local.all_servers) - length(local.enabled_servers)
}

output "manifest_path" {
  description = "Path to the generated deployment manifest JSON file"
  value       = local_file.deployment_manifest.filename
}

output "config_summary" {
  description = "Summary of the parsed JSON configuration"
  value = {
    environment      = local.config.environment
    total_servers    = length(local.config.servers)
    enabled_servers  = length(local.enabled_servers)
    tags             = local.config.tags
  }
}