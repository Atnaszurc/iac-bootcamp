# AWS-204: Advanced Patterns
# Demonstrates: Auto Scaling Group, Application Load Balancer, Launch Template
# Provider: hashicorp/aws
# Run: terraform init && terraform apply
#
# Prerequisites: AWS credentials configured (see AWS-201)
# Cost: ALB ~$0.008/LCU-hour; ASG instances billed per EC2 rate

terraform {
  required_version = ">= 1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Course      = "AWS-204"
      Environment = var.environment
      Project     = var.project_name
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Data sources
# ─────────────────────────────────────────────────────────────────────────────

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# VPC & Networking
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-public-${count.index + 1}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ─────────────────────────────────────────────────────────────────────────────
# Security Groups
# AWS provider v6: inline ingress/egress blocks in aws_security_group are
# deprecated. The modern approach uses separate aws_vpc_security_group_ingress_rule
# and aws_vpc_security_group_egress_rule resources. Inline rules still work in v6
# but will be removed in a future major version. This example retains inline rules
# for simplicity and readability in a training context.
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP inbound to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

resource "aws_security_group" "instances" {
  name        = "${var.project_name}-instances-sg"
  description = "Allow HTTP from ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-instances-sg" }
}

# ─────────────────────────────────────────────────────────────────────────────
# Application Load Balancer
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Launch Template
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instances.id]

  # AWS provider v6: aws_instance.user_data is stored in cleartext (no longer hashed).
  # Launch templates use user_data as base64-encoded content — this is the correct
  # approach. Do NOT include passwords or sensitive data in user_data.
  user_data = base64encode(<<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    echo "<h1>Hello from instance: $INSTANCE_ID</h1>" > /var/www/html/index.html
  EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project_name}-web"
      Project = var.project_name
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Auto Scaling Group
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-asg"
  desired_capacity    = var.asg_desired
  min_size            = var.asg_min
  max_size            = var.asg_max
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────────────────────────────────────

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "URL to access the load-balanced application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}