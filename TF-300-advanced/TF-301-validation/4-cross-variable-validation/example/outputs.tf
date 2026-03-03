output "deployment_summary" {
  description = "Summary of the validated deployment configuration"
  value = {
    environment    = var.environment
    project_name   = var.project_name
    name_prefix    = local.name_prefix
    instance_count = var.instance_count
    disk_size_gb   = var.disk_size_gb
    backups        = local.backup_summary
  }
}

output "config_report_path" {
  description = "Path to the generated configuration report file"
  value       = local_file.config_report.filename
}