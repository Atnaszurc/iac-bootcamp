# MC-304: Advanced Multi-Cloud Patterns - Tests
# Uses mock_provider for both AWS and Azure (no credentials required)
# Key tests: observability config, DR failover, cost optimization, tagging
# Requires Terraform >= 1.7.0

mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id           = "ami-0abcdef1234567890"
      name         = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20240101"
      owner_id     = "099720109477"
      architecture = "x86_64"
    }
  }
}

mock_provider "azurerm" {}

# ---------------------------------------------------------------------------
# Run 1: Default dev environment configuration
# ---------------------------------------------------------------------------

run "dev_environment_defaults" {
  command = plan

  assert {
    condition     = var.environment == "dev"
    error_message = "Default environment should be 'dev'."
  }

  assert {
    condition     = local.sizing.aws_instance_type == "t3.micro"
    error_message = "Dev environment should use t3.micro."
  }

  assert {
    condition     = local.sizing.azure_vm_size == "Standard_B1s"
    error_message = "Dev environment should use Standard_B1s."
  }

  assert {
    condition     = local.sizing.min_instances == 1
    error_message = "Dev environment should have min 1 instance."
  }
}

# ---------------------------------------------------------------------------
# Run 2: Cost allocation tags applied to all resources
# ---------------------------------------------------------------------------

run "cost_allocation_tags" {
  command = plan

  variables {
    project_name = "cost-test"
    team_name    = "finance-team"
    cost_center  = "CC-5678"
  }

  assert {
    condition     = local.cost_tags["CostCenter"] == "CC-5678"
    error_message = "Cost tags must include correct CostCenter."
  }

  assert {
    condition     = local.cost_tags["Team"] == "finance-team"
    error_message = "Cost tags must include correct Team."
  }

  assert {
    condition     = local.cost_tags["ManagedBy"] == "Terraform"
    error_message = "Cost tags must include ManagedBy = Terraform."
  }

  assert {
    condition     = aws_instance.primary.tags["CostCenter"] == "CC-5678"
    error_message = "AWS primary instance must have CostCenter tag."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.standby.tags["CostCenter"] == "CC-5678"
    error_message = "Azure standby VM must have CostCenter tag."
  }
}

# ---------------------------------------------------------------------------
# Run 3: CloudWatch observability configuration
# ---------------------------------------------------------------------------

run "cloudwatch_observability" {
  command = plan

  variables {
    log_retention_days  = 30
    cpu_alert_threshold = 80
    alert_email         = "ops@example.com"
  }

  assert {
    condition     = aws_cloudwatch_log_group.app.retention_in_days == 30
    error_message = "CloudWatch log group should retain logs for 30 days."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.high_cpu.threshold == 80
    error_message = "CloudWatch CPU alarm threshold should be 80."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.high_cpu.metric_name == "CPUUtilization"
    error_message = "CloudWatch alarm should monitor CPUUtilization."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.high_cpu.namespace == "AWS/EC2"
    error_message = "CloudWatch alarm namespace should be AWS/EC2."
  }

  assert {
    condition     = aws_sns_topic_subscription.email.protocol == "email"
    error_message = "SNS subscription should use email protocol."
  }

  assert {
    condition     = aws_sns_topic_subscription.email.endpoint == "ops@example.com"
    error_message = "SNS subscription endpoint should match alert_email."
  }
}

# ---------------------------------------------------------------------------
# Run 4: Azure Monitor observability configuration
# ---------------------------------------------------------------------------

run "azure_monitor_observability" {
  command = plan

  variables {
    log_retention_days  = 30
    cpu_alert_threshold = 80
    alert_email         = "ops@example.com"
  }

  assert {
    condition     = azurerm_log_analytics_workspace.main.retention_in_days == 30
    error_message = "Azure Log Analytics should retain logs for 30 days."
  }

  assert {
    condition     = azurerm_monitor_metric_alert.high_cpu.criteria[0].threshold == 80
    error_message = "Azure CPU alert threshold should be 80."
  }

  assert {
    condition     = azurerm_monitor_metric_alert.high_cpu.criteria[0].metric_name == "Percentage CPU"
    error_message = "Azure alert should monitor 'Percentage CPU'."
  }

  assert {
    condition     = azurerm_monitor_action_group.main.email_receiver[0].email_address == "ops@example.com"
    error_message = "Azure action group email should match alert_email."
  }
}

# ---------------------------------------------------------------------------
# Run 5: Both clouds use the same alert threshold (unified observability)
# ---------------------------------------------------------------------------

run "unified_alert_threshold" {
  command = plan

  variables {
    cpu_alert_threshold = 75
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.high_cpu.threshold == 75
    error_message = "AWS CPU alarm threshold should be 75."
  }

  assert {
    condition     = azurerm_monitor_metric_alert.high_cpu.criteria[0].threshold == 75
    error_message = "Azure CPU alert threshold should be 75."
  }
}

# ---------------------------------------------------------------------------
# Run 6: DR - Route53 failover routing configured
# ---------------------------------------------------------------------------

run "dr_failover_routing" {
  command = plan

  assert {
    condition     = aws_route53_health_check.primary.port == 443
    error_message = "Health check should monitor port 443."
  }

  assert {
    condition     = aws_route53_health_check.primary.type == "HTTPS"
    error_message = "Health check type should be HTTPS."
  }

  assert {
    condition     = aws_route53_health_check.primary.failure_threshold == 3
    error_message = "Health check failure threshold should be 3."
  }

  assert {
    condition     = aws_route53_record.app_primary.failover_routing_policy[0].type == "PRIMARY"
    error_message = "AWS DNS record should be PRIMARY in failover policy."
  }

  assert {
    condition     = aws_route53_record.app_secondary.failover_routing_policy[0].type == "SECONDARY"
    error_message = "Azure DNS record should be SECONDARY in failover policy."
  }
}

# ---------------------------------------------------------------------------
# Run 7: DR - Azure standby VM tagged correctly
# ---------------------------------------------------------------------------

run "dr_standby_tagging" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine.standby.tags["Role"] == "standby"
    error_message = "Azure standby VM should have Role=standby tag."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.standby.tags["DR"] == "true"
    error_message = "Azure standby VM should have DR=true tag."
  }
}

# ---------------------------------------------------------------------------
# Run 8: Cost optimization - scheduled scaling only for non-prod
# ---------------------------------------------------------------------------

run "scheduled_scaling_dev" {
  command = plan

  variables {
    environment = "dev"
  }

  # In dev, scheduled scaling should be created (count = 1)
  assert {
    condition     = length(aws_autoscaling_schedule.scale_down_night) == 1
    error_message = "Scheduled scale-down should be created for dev environment."
  }

  assert {
    condition     = length(aws_autoscaling_schedule.scale_up_morning) == 1
    error_message = "Scheduled scale-up should be created for dev environment."
  }

  assert {
    condition     = aws_autoscaling_schedule.scale_down_night[0].desired_capacity == 0
    error_message = "Scale-down schedule should set desired capacity to 0."
  }

  assert {
    condition     = aws_autoscaling_schedule.scale_down_night[0].recurrence == "0 18 * * MON-FRI"
    error_message = "Scale-down should run at 6 PM UTC on weekdays."
  }
}

# ---------------------------------------------------------------------------
# Run 9: Cost optimization - no scheduled scaling in prod
# ---------------------------------------------------------------------------

run "no_scheduled_scaling_prod" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = length(aws_autoscaling_schedule.scale_down_night) == 0
    error_message = "Scheduled scale-down should NOT be created for prod environment."
  }

  assert {
    condition     = length(aws_autoscaling_schedule.scale_up_morning) == 0
    error_message = "Scheduled scale-up should NOT be created for prod environment."
  }
}

# ---------------------------------------------------------------------------
# Run 10: Prod environment uses larger instance sizes
# ---------------------------------------------------------------------------

run "prod_sizing" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = local.sizing.aws_instance_type == "t3.medium"
    error_message = "Prod should use t3.medium."
  }

  assert {
    condition     = local.sizing.azure_vm_size == "Standard_D2s_v3"
    error_message = "Prod should use Standard_D2s_v3."
  }

  assert {
    condition     = local.sizing.min_instances == 2
    error_message = "Prod should have minimum 2 instances."
  }

  assert {
    condition     = local.sizing.max_instances == 10
    error_message = "Prod should allow up to 10 instances."
  }
}