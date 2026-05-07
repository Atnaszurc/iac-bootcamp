terraform {
  required_version = ">= 1.15.0"
}

# ============================================================================
# Example Resources for Output Type Constraints
# ============================================================================

# Simulate application configuration
resource "terraform_data" "app_config" {
  input = {
    name        = var.app_name
    version     = var.app_version
    environment = var.environment
    port        = var.port
    enabled     = var.enabled
  }
}

# Simulate multiple instances
resource "terraform_data" "instances" {
  count = var.instance_count

  input = {
    id         = "instance-${count.index + 1}"
    name       = "${var.app_name}-${count.index + 1}"
    ip_address = "10.0.${count.index + 1}.10"
    state      = "running"
    type       = var.instance_type
  }
}

# Simulate database configuration
resource "terraform_data" "database" {
  input = {
    endpoint = "${var.app_name}-db.example.com"
    port     = 5432
    username = "admin"
    database = var.app_name
    ssl      = true
  }
}

# Simulate network configuration
resource "terraform_data" "network" {
  input = {
    vpc_id     = "vpc-12345"
    cidr_block = "10.0.0.0/16"
    subnets = [
      {
        id   = "subnet-1"
        cidr = "10.0.1.0/24"
        az   = "us-east-1a"
      },
      {
        id   = "subnet-2"
        cidr = "10.0.2.0/24"
        az   = "us-east-1b"
      }
    ]
  }
}

# Simulate load balancer
resource "terraform_data" "load_balancer" {
  input = {
    dns_name = "${var.app_name}-lb.example.com"
    arn      = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/${var.app_name}-lb/1234567890abcdef"
    port     = 443
    protocol = "HTTPS"
  }
}