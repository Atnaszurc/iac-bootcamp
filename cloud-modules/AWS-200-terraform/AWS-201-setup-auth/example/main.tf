# AWS-201: Setup & Authentication
# Demonstrates: AWS provider configuration, authentication methods
# Provider: hashicorp/aws
# Run: terraform init && terraform plan
#
# Prerequisites:
#   - AWS CLI installed and configured (aws configure)
#   - OR environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION
#   - OR IAM role (when running on EC2/ECS/Lambda)
#
# See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

terraform {
  required_version = ">= 1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider configuration
# Authentication is resolved in this order:
#   1. Static credentials (not recommended for production)
#   2. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
#   3. Shared credentials file (~/.aws/credentials)
#   4. IAM instance profile (EC2/ECS/Lambda)
# ─────────────────────────────────────────────────────────────────────────────

provider "aws" {
  region = var.aws_region

  # Optional: use a named profile from ~/.aws/credentials
  # profile = "my-profile"

  # Optional: assume a role before making API calls
  # assume_role {
  #   role_arn = "arn:aws:iam::123456789012:role/TerraformRole"
  # }

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Course      = "AWS-201"
      Environment = var.environment
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Verify authentication: read caller identity
# ─────────────────────────────────────────────────────────────────────────────

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# ─────────────────────────────────────────────────────────────────────────────
# Outputs — verify what account/region we're connected to
# ─────────────────────────────────────────────────────────────────────────────

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  description = "ARN of the caller (user or role)"
  value       = data.aws_caller_identity.current.arn
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.region # v6: .name deprecated, use .region
}

output "availability_zones" {
  description = "Available AZs in this region"
  value       = data.aws_availability_zones.available.names
}