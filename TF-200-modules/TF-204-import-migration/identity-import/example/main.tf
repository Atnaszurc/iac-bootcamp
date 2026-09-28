# TF-204 Supplement: Identity-Based Import (Terraform 1.12+)
#
# Imports the resources seed/ created, using `identity` instead of `id`.
# Needs Moto running (see the README).
#
#   (cd seed && terraform init && terraform apply && rm terraform.tfstate*)
#   terraform init
#   terraform plan      # 5 to import, 0 to add, 0 to change, 0 to destroy
#   terraform apply

locals {
  assume_ec2 = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# ── A bucket: identity = { bucket } ─────────────────────────────────────────

import {
  to = aws_s3_bucket.data
  identity = {
    bucket = "legacy-data-prod"
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "legacy-data-prod"
}

# ── Several roles at once: for_each + identity = { name } ───────────────────

variable "roles_to_import" {
  type    = set(string)
  default = ["legacy-deployer", "legacy-readonly"]
}

import {
  for_each = var.roles_to_import
  to       = aws_iam_role.roles[each.key]
  identity = {
    name = each.key
  }
}

resource "aws_iam_role" "roles" {
  for_each = var.roles_to_import

  name               = each.key
  assume_role_policy = local.assume_ec2
}

# ── A policy: identity = { arn } ────────────────────────────────────────────
# Moto's account ID is always 123456789012

locals {
  read_logs_arn = "arn:aws:iam::123456789012:policy/legacy-read-logs"
}

import {
  to = aws_iam_policy.read_logs
  identity = {
    arn = local.read_logs_arn
  }
}

resource "aws_iam_policy" "read_logs" {
  name = "legacy-read-logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:GetLogEvents", "logs:DescribeLogStreams"]
      Resource = "*"
    }]
  })
}

# ── A composite identity: role + policy_arn ─────────────────────────────────
# With `id` you'd need to know the format: "<role>/<policy_arn>"

import {
  to = aws_iam_role_policy_attachment.read_logs
  identity = {
    role       = "legacy-readonly"
    policy_arn = local.read_logs_arn
  }
}

resource "aws_iam_role_policy_attachment" "read_logs" {
  role       = aws_iam_role.roles["legacy-readonly"].name
  policy_arn = aws_iam_policy.read_logs.arn
}
