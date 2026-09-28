output "config_files" {
  description = "Generated service config files"
  value       = { for name, f in local_file.service_config : name => f.filename }
}

output "audit_log" {
  description = "File that every action appends to"
  value       = local.audit_log
}
