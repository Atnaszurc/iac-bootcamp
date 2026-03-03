# TF-204 Supplement: Identity-Based Import (Terraform 1.12+)
#
# This example demonstrates the SYNTAX of identity-based import blocks.
# The local provider does not implement identity-based import, so the
# identity blocks are shown as comments for reference.
#
# For a working import example, see the parent example/ directory which
# uses traditional id-based import with the local provider.
#
# In production with a supporting provider (e.g., AWS provider 6.x+):
#   terraform init
#   terraform plan   # Shows what will be imported
#   terraform apply  # Performs the import

terraform {
  required_version = ">= 1.14"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# TRADITIONAL IMPORT — using string id (Terraform 1.5+)
# Works with all providers that support import
# ─────────────────────────────────────────────────────────────────────────────

# Step 1: Create the file manually (simulates pre-existing infrastructure)
# In a real scenario, this resource already exists and was NOT created by Terraform

# Step 2: Import it using traditional string id
import {
  to = local_file.existing_config
  id = "${path.module}/output/existing.conf"  # local_file ID = absolute file path
}

# Step 3: Define the resource configuration to match the existing resource
resource "local_file" "existing_config" {
  filename = "${path.module}/output/existing.conf"
  content  = "# Existing configuration file\napp_name = legacy-app\n"
}

# ─────────────────────────────────────────────────────────────────────────────
# IDENTITY-BASED IMPORT SYNTAX — for reference (Terraform 1.12+)
# Uncomment and adapt when using a provider that supports identity
# ─────────────────────────────────────────────────────────────────────────────

# Example 1: AWS IAM Role (requires AWS provider 6.x+ with identity support)
#
# import {
#   to = aws_iam_role.admin
#   identity = {
#     name = "my-admin-role"   # Named attribute — no need to know string ID format
#   }
# }
#
# resource "aws_iam_role" "admin" {
#   name = "my-admin-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action    = "sts:AssumeRole"
#       Effect    = "Allow"
#       Principal = { Service = "ec2.amazonaws.com" }
#     }]
#   })
# }

# Example 2: AWS S3 Bucket
#
# import {
#   to = aws_s3_bucket.data
#   identity = {
#     bucket = "my-data-bucket-prod"   # Explicit attribute name
#   }
# }
#
# resource "aws_s3_bucket" "data" {
#   bucket = "my-data-bucket-prod"
# }

# Example 3: Composite resource — where identity really shines
# Traditional id uses a separator: "my-bucket,private"
# Identity uses named attributes — much clearer!
#
# import {
#   to = aws_s3_bucket_acl.main
#   identity = {
#     bucket = "my-bucket"
#     acl    = "private"
#   }
# }
#
# resource "aws_s3_bucket_acl" "main" {
#   bucket = "my-bucket"
#   acl    = "private"
# }

# Example 4: Bulk import with for_each + identity
#
# locals {
#   roles = {
#     admin    = { name = "my-admin-role" }
#     deployer = { name = "my-deployer-role" }
#     readonly = { name = "my-readonly-role" }
#   }
# }
#
# import {
#   for_each = local.roles
#   to       = aws_iam_role.roles[each.key]
#   identity = {
#     name = each.value.name
#   }
# }
#
# resource "aws_iam_role" "roles" {
#   for_each = local.roles
#   name     = each.value.name
#   # ... assume_role_policy etc.
# }

# ─────────────────────────────────────────────────────────────────────────────
# COMPARISON: id vs identity — side by side
# ─────────────────────────────────────────────────────────────────────────────

# The key difference:
#
# BEFORE (id — string, must know exact format):
#   import {
#     to = aws_s3_bucket_acl.main
#     id = "my-bucket,private"   # What separator? What order? Must check docs!
#   }
#
# AFTER (identity — structured, self-documenting):
#   import {
#     to = aws_s3_bucket_acl.main
#     identity = {
#       bucket = "my-bucket"     # Clear: this is the bucket name
#       acl    = "private"       # Clear: this is the ACL value
#     }
#   }
#
# RULE: id and identity are MUTUALLY EXCLUSIVE — use one or the other.