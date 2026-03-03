# TF-405 Example: Multi-Component Web Application Stack
# This stack deploys a complete web application with networking, database, and compute components
# Requires: HCP Terraform with Stacks enabled, Terraform 1.13+

# Stack-level variables
variable "region" {
  type        = string
  description = "AWS region for deployment"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for application servers"
  default     = "t3.micro"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

# Provider configuration
provider "aws" "main" {
  config {
    region = var.region
    
    default_tags {
      tags = {
        Environment = var.environment
        ManagedBy   = "Terraform-Stacks"
        Stack       = "web-application"
      }
    }
  }
}

# Component 1: Networking
# Creates VPC, subnets, security groups, and NAT gateway
component "networking" {
  source = "./components/networking"

  providers = {
    aws = provider.aws.main
  }

  inputs = {
    environment = var.environment
    vpc_cidr    = "10.0.0.0/16"
  }
}

# Component 2: Database
# Creates RDS PostgreSQL instance in private subnets
component "database" {
  source = "./components/database"

  providers = {
    aws = provider.aws.main
  }

  inputs = {
    environment       = var.environment
    vpc_id            = component.networking.vpc_id
    subnet_ids        = component.networking.private_subnet_ids
    db_instance_class = var.db_instance_class
    db_name           = "appdb"
  }

  # Explicit dependency - database needs networking first
  depends_on = [component.networking]
}

# Component 3: Compute
# Creates EC2 instances, load balancer, and auto-scaling group
component "compute" {
  source = "./components/compute"

  providers = {
    aws = provider.aws.main
  }

  inputs = {
    environment     = var.environment
    vpc_id          = component.networking.vpc_id
    public_subnets  = component.networking.public_subnet_ids
    private_subnets = component.networking.private_subnet_ids
    instance_type   = var.instance_type
    
    # Pass database connection info to compute instances
    db_endpoint     = component.database.endpoint
    db_secret_arn   = component.database.secret_arn
  }

  # Explicit dependencies - compute needs both networking and database
  depends_on = [
    component.networking,
    component.database
  ]
}