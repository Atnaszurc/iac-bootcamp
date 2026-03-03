# MC-304: Advanced Multi-Cloud Patterns
# Demonstrates: unified observability (CloudWatch + Azure Monitor),
# active-passive DR with Route53 health check failover,
# and cost optimization with scheduled scaling for non-prod environments.

terraform {
  required_version = ">= 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

# ---------------------------------------------------------------------------
# Locals: cost allocation tags and environment config
# ---------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Cost allocation tags - applied to every resource in both clouds
  cost_tags = {
    Project     = var.project_name
    Environment = var.environment
    Team        = var.team_name
    CostCenter  = var.cost_center
    ManagedBy   = "Terraform"
    Cloud       = "multi-cloud"
  }

  # Resolve environment-specific sizing
  sizing = var.environment_sizing[var.environment]
}

# ===========================================================================
# AWS FOUNDATION
# ===========================================================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.cost_tags, {
    Name  = "${local.name_prefix}-vpc"
    Cloud = "AWS"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = merge(local.cost_tags, {
    Name  = "${local.name_prefix}-public"
    Cloud = "AWS"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.cost_tags, {
    Name  = "${local.name_prefix}-igw"
    Cloud = "AWS"
  })
}

# ---------------------------------------------------------------------------
# AWS: Primary application instance (active in DR pattern)
# ---------------------------------------------------------------------------

# AWS provider v6: inline ingress/egress blocks in aws_security_group are deprecated.
# Modern code uses aws_vpc_security_group_ingress_rule / aws_vpc_security_group_egress_rule.
# Inline rules still work in v6 but will be removed in a future major version.
resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Web server security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.cost_tags, {
    Name  = "${local.name_prefix}-web-sg"
    Cloud = "AWS"
  })
}

resource "aws_instance" "primary" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = local.sizing.aws_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = merge(local.cost_tags, {
    Name  = "${local.name_prefix}-primary"
    Cloud = "AWS"
    Role  = "primary"
  })
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ===========================================================================
# AWS OBSERVABILITY: CloudWatch
# ===========================================================================

resource "aws_cloudwatch_log_group" "app" {
  name              = "/app/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = merge(local.cost_tags, {
    Cloud = "AWS"
  })
}

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = merge(local.cost_tags, {
    Cloud = "AWS"
  })
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.name_prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_alert_threshold
  alarm_description   = "CPU utilization > ${var.cpu_alert_threshold}%"

  dimensions = {
    InstanceId = aws_instance.primary.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = merge(local.cost_tags, {
    Cloud = "AWS"
  })
}

# ===========================================================================
# AWS DISASTER RECOVERY: Route53 health check + failover routing
# ===========================================================================

resource "aws_eip" "primary" {
  instance = aws_instance.primary.id
  domain   = "vpc"

  tags = merge(local.cost_tags, {
    Name  = "${local.name_prefix}-primary-eip"
    Cloud = "AWS"
  })
}

resource "aws_route53_zone" "public" {
  name = var.domain_name

  tags = merge(local.cost_tags, {
    Cloud = "AWS"
  })
}

resource "aws_route53_health_check" "primary" {
  fqdn              = aws_instance.primary.public_dns
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(local.cost_tags, {
    Name  = "${local.name_prefix}-primary-hc"
    Cloud = "AWS"
  })
}

# Primary DNS record (AWS) - active in normal operation
resource "aws_route53_record" "app_primary" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"
  ttl     = 60

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "primary-aws"
  health_check_id = aws_route53_health_check.primary.id
  records         = [aws_eip.primary.public_ip]
}

# Secondary DNS record (Azure) - activated when AWS health check fails
resource "aws_route53_record" "app_secondary" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"
  ttl     = 60

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "secondary-azure"
  records        = [azurerm_public_ip.standby.ip_address]
}

# ===========================================================================
# AZURE FOUNDATION
# ===========================================================================

resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.azure_region

  tags = merge(local.cost_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_virtual_network" "main" {
  name                = "${local.name_prefix}-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(local.cost_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_subnet" "public" {
  name                 = "${local.name_prefix}-public"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.1.0/24"]
}

# ---------------------------------------------------------------------------
# Azure: Standby instance (passive in DR pattern)
# ---------------------------------------------------------------------------

resource "azurerm_public_ip" "standby" {
  name                = "${local.name_prefix}-standby-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(local.cost_tags, {
    Cloud = "Azure"
    Role  = "standby"
  })
}

resource "azurerm_network_interface" "standby" {
  name                = "${local.name_prefix}-standby-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.standby.id
  }

  tags = merge(local.cost_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_linux_virtual_machine" "standby" {
  name                = "${local.name_prefix}-standby"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = local.sizing.azure_vm_size
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.standby.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDY5O6Vlecaw4jVcv15DNFm5VJYtWcjKPpentQHWNcuFCUl/7TAR+3B418mWGZhgDbExH+ipVyq+Bz9hS5wugYjSsaiMPa5X2wjKSCMOwUWnluzUgSFnHhyj45NWFI0S7atbU9sqGE5tqXEh1tMqkIkp1tWJexKMd4Q8M4nCJVMOtcG2CWuh7BUdJLPcMzOaYGgSNxaOvabpT8+cMoVINrIVd1UTwKi7h5WthKID72drCt2lHG1pzQnPK6DkzjTbGlul/19Lm1d8DjMAg7GMXAEaa7dbWIt4LrZCNCv/0oZ0XQlxWxl1INgKEuOIsLjf4geafwqiEGtZdcZFFjPIplt standby@example.com"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = merge(local.cost_tags, {
    Cloud = "Azure"
    Role  = "standby"
    DR    = "true"
  })
}

# ===========================================================================
# AZURE OBSERVABILITY: Log Analytics + Monitor
# ===========================================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.name_prefix}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = merge(local.cost_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_monitor_action_group" "main" {
  name                = "${local.name_prefix}-ag"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "alerts"

  email_receiver {
    name          = "ops-team"
    email_address = var.alert_email
  }

  tags = merge(local.cost_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "${local.name_prefix}-high-cpu"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_virtual_machine.standby.id]
  description         = "CPU utilization > ${var.cpu_alert_threshold}%"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = merge(local.cost_tags, {
    Cloud = "Azure"
  })
}

# ===========================================================================
# COST OPTIMIZATION: Scheduled scaling for non-prod environments
# Only created when environment != "prod"
# ===========================================================================

resource "aws_autoscaling_group" "web" {
  name             = "${local.name_prefix}-asg"
  min_size         = local.sizing.min_instances
  max_size         = local.sizing.max_instances
  desired_capacity = local.sizing.min_instances

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.public.id]

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-web"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "${local.name_prefix}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = local.sizing.aws_instance_type

  # AWS provider v6: aws_instance.user_data is stored in cleartext (no longer hashed).
  # Do NOT include passwords or sensitive data in user_data.
  # Use user_data_base64 for pre-encoded content, or pass secrets via SSM / Secrets Manager.

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.cost_tags, {
      Name  = "${local.name_prefix}-web"
      Cloud = "AWS"
    })
  }
}

# Scale down at 6 PM on weekdays (non-prod only)
resource "aws_autoscaling_schedule" "scale_down_night" {
  count = var.environment != "prod" ? 1 : 0

  scheduled_action_name  = "scale-down-night"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "0 18 * * MON-FRI" # 6 PM UTC weekdays
  autoscaling_group_name = aws_autoscaling_group.web.name
}

# Scale up at 8 AM on weekdays (non-prod only)
resource "aws_autoscaling_schedule" "scale_up_morning" {
  count = var.environment != "prod" ? 1 : 0

  scheduled_action_name  = "scale-up-morning"
  min_size               = local.sizing.min_instances
  max_size               = local.sizing.max_instances
  desired_capacity       = local.sizing.min_instances
  recurrence             = "0 8 * * MON-FRI" # 8 AM UTC weekdays
  autoscaling_group_name = aws_autoscaling_group.web.name
}