# MC-304: Advanced Multi-Cloud Patterns - Outputs

# ---------------------------------------------------------------------------
# Configuration summary
# ---------------------------------------------------------------------------

output "environment" {
  description = "Active deployment environment"
  value       = var.environment
}

output "active_sizing" {
  description = "Active environment sizing configuration"
  value       = local.sizing
}

output "cost_tags" {
  description = "Cost allocation tags applied to all resources"
  value       = local.cost_tags
}

# ---------------------------------------------------------------------------
# AWS outputs
# ---------------------------------------------------------------------------

output "aws_primary_instance_id" {
  description = "AWS primary instance ID"
  value       = aws_instance.primary.id
}

output "aws_primary_public_ip" {
  description = "AWS primary instance Elastic IP"
  value       = aws_eip.primary.public_ip
}

output "aws_cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.app.name
}

output "aws_cloudwatch_log_retention_days" {
  description = "CloudWatch log retention in days"
  value       = aws_cloudwatch_log_group.app.retention_in_days
}

output "aws_sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "aws_cpu_alarm_threshold" {
  description = "CPU alarm threshold percentage"
  value       = aws_cloudwatch_metric_alarm.high_cpu.threshold
}

output "aws_route53_zone_id" {
  description = "Route53 public hosted zone ID"
  value       = aws_route53_zone.public.zone_id
}

output "aws_health_check_id" {
  description = "Route53 health check ID for primary instance"
  value       = aws_route53_health_check.primary.id
}

output "aws_asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.web.name
}

output "aws_asg_min_size" {
  description = "Auto Scaling Group minimum size"
  value       = aws_autoscaling_group.web.min_size
}

output "aws_asg_max_size" {
  description = "Auto Scaling Group maximum size"
  value       = aws_autoscaling_group.web.max_size
}

output "aws_scheduled_scaling_enabled" {
  description = "Whether scheduled scaling is enabled (non-prod only)"
  value       = var.environment != "prod"
}

# ---------------------------------------------------------------------------
# Azure outputs
# ---------------------------------------------------------------------------

output "azure_resource_group_name" {
  description = "Azure resource group name"
  value       = azurerm_resource_group.main.name
}

output "azure_standby_vm_id" {
  description = "Azure standby VM resource ID"
  value       = azurerm_linux_virtual_machine.standby.id
}

output "azure_standby_public_ip" {
  description = "Azure standby VM public IP address"
  value       = azurerm_public_ip.standby.ip_address
}

output "azure_log_analytics_workspace_id" {
  description = "Azure Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "azure_log_retention_days" {
  description = "Azure Log Analytics retention in days"
  value       = azurerm_log_analytics_workspace.main.retention_in_days
}

output "azure_action_group_id" {
  description = "Azure Monitor Action Group ID"
  value       = azurerm_monitor_action_group.main.id
}

output "azure_cpu_alert_threshold" {
  description = "Azure CPU alert threshold percentage"
  value       = azurerm_monitor_metric_alert.high_cpu.criteria[0].threshold
}

# ---------------------------------------------------------------------------
# DR summary
# ---------------------------------------------------------------------------

output "dr_configuration" {
  description = "Disaster recovery configuration summary"
  value = {
    primary = {
      cloud      = "AWS"
      region     = var.aws_region
      public_ip  = aws_eip.primary.public_ip
      dns_record = "app.${var.domain_name}"
      role       = "PRIMARY"
    }
    standby = {
      cloud      = "Azure"
      region     = var.azure_region
      public_ip  = azurerm_public_ip.standby.ip_address
      dns_record = "app.${var.domain_name}"
      role       = "SECONDARY"
    }
    health_check_path      = "/health"
    health_check_interval  = 30
    failover_threshold     = 3
  }
}

# ---------------------------------------------------------------------------
# Observability summary
# ---------------------------------------------------------------------------

output "observability_summary" {
  description = "Unified observability configuration across both clouds"
  value = {
    aws = {
      log_group       = aws_cloudwatch_log_group.app.name
      retention_days  = aws_cloudwatch_log_group.app.retention_in_days
      alert_topic     = aws_sns_topic.alerts.arn
      cpu_threshold   = aws_cloudwatch_metric_alarm.high_cpu.threshold
    }
    azure = {
      log_workspace   = azurerm_log_analytics_workspace.main.name
      retention_days  = azurerm_log_analytics_workspace.main.retention_in_days
      action_group    = azurerm_monitor_action_group.main.name
      cpu_threshold   = azurerm_monitor_metric_alert.high_cpu.criteria[0].threshold
    }
    shared = {
      alert_email     = var.alert_email
      log_retention   = var.log_retention_days
      cpu_threshold   = var.cpu_alert_threshold
    }
  }
}