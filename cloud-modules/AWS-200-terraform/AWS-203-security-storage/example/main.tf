# AWS-203: Security & Storage
# Demonstrates: S3 bucket, IAM role + policy, EBS volume attachment
# Provider: hashicorp/aws
# Run: terraform init && terraform apply
#
# Prerequisites: AWS credentials configured (see AWS-201)
# Cost: S3 and IAM are free; EBS gp3 ~$0.08/GB/month

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
      Course      = "AWS-203"
      Environment = var.environment
      Project     = var.project_name
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# S3 Bucket
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-bucket"
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─────────────────────────────────────────────────────────────────────────────
# IAM Role (for EC2 to access S3)
# ─────────────────────────────────────────────────────────────────────────────

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2_s3_role" {
  name               = "${var.project_name}-ec2-s3-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${var.project_name}-ec2-s3-role"
  }
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "s3_access" {
  name   = "${var.project_name}-s3-access"
  role   = aws_iam_role.ec2_s3_role.id
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_s3_role.name
}

# ─────────────────────────────────────────────────────────────────────────────
# EBS Volume (additional data disk)
# ─────────────────────────────────────────────────────────────────────────────

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_ebs_volume" "data" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = var.ebs_size_gb
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${var.project_name}-data-volume"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────────────────────────────────────

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2"
  value       = aws_iam_role.ec2_s3_role.arn
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ebs_volume_id" {
  description = "ID of the EBS data volume"
  value       = aws_ebs_volume.data.id
}