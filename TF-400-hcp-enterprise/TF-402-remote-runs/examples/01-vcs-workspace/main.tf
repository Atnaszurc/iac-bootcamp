# TF-402 Example: VCS-Driven Workspace
#
# This configuration is designed to be connected to a GitHub repository
# via HCP Terraform's VCS integration.
#
# How it works:
#   1. Connect this repo to HCP Terraform (UI: New Workspace → VCS)
#   2. Set working directory to this folder
#   3. Open a PR → HCP Terraform posts a speculative plan as a PR comment
#   4. Merge the PR → HCP Terraform runs terraform apply automatically
#
# NOTE: The `cloud` block below is for CLI-driven use.
#       For VCS-driven workspaces, the cloud block is optional —
#       HCP Terraform manages the connection via the UI.

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
# Variables — set these in HCP Terraform workspace variables (not .tfvars)
# ─────────────────────────────────────────────────────────────────────────────

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, production)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "app_version" {
  type        = string
  description = "Application version to deploy"
  default     = "1.0.0"
}

# ─────────────────────────────────────────────────────────────────────────────
# Resources
# ─────────────────────────────────────────────────────────────────────────────

locals {
  deployment_config = {
    environment = var.environment
    app_version = var.app_version
    deployed_by = "HCP Terraform (VCS-driven)"
    workspace   = terraform.workspace
  }
}

resource "local_file" "deployment_config" {
  content  = jsonencode(local.deployment_config)
  filename = "${path.module}/output/deployment-${var.environment}.json"
}

resource "local_file" "readme" {
  content  = <<-EOT
    Deployment: ${var.environment}
    Version: ${var.app_version}
    Managed by: HCP Terraform
    
    This file was created by a VCS-driven workspace.
    Changes to this repository trigger automatic plans and applies.
  EOT
  filename = "${path.module}/output/README.txt"
}

# ─────────────────────────────────────────────────────────────────────────────
# Outputs — visible in HCP Terraform run output
# ─────────────────────────────────────────────────────────────────────────────

output "environment" {
  value       = var.environment
  description = "The deployment environment"
}

output "app_version" {
  value       = var.app_version
  description = "The deployed application version"
}