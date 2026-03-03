# TF-402 Example: Run Triggers & Workspace Dependencies
#
# This example uses the `tfe` provider to configure HCP Terraform
# workspaces and run triggers programmatically (meta-Terraform).
#
# Scenario:
#   - `networking` workspace manages VPC, subnets, security groups
#   - `application` workspace manages VMs/containers that depend on networking
#   - When `networking` applies successfully, `application` is automatically triggered
#
# This is "meta-Terraform" — using Terraform to configure Terraform.
#
# Prerequisites:
#   - HCP Terraform organization
#   - TFE_TOKEN environment variable set (or terraform login)
#   - Both workspaces must already exist (or be created here)

terraform {
  required_version = ">= 1.14"

  required_providers {
    # The TFE provider manages HCP Terraform resources
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.74"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Variables
# ─────────────────────────────────────────────────────────────────────────────

variable "organization" {
  type        = string
  description = "HCP Terraform organization name"
}

# ─────────────────────────────────────────────────────────────────────────────
# Workspaces
# ─────────────────────────────────────────────────────────────────────────────

# Networking workspace — manages foundational infrastructure
resource "tfe_workspace" "networking" {
  name         = "networking"
  organization = var.organization
  description  = "Manages VPC, subnets, and security groups"

  # Auto-apply after successful plan (appropriate for networking layer)
  auto_apply = false

  tag_names = ["layer:networking", "team:platform"]
}

# Application workspace — depends on networking outputs
resource "tfe_workspace" "application" {
  name         = "application"
  organization = var.organization
  description  = "Manages application VMs — depends on networking workspace"

  # Require manual approval for application deployments
  auto_apply = false

  tag_names = ["layer:application", "team:app"]
}

# ─────────────────────────────────────────────────────────────────────────────
# Run Trigger: application runs when networking applies
# ─────────────────────────────────────────────────────────────────────────────

resource "tfe_workspace_run_trigger" "app_depends_on_network" {
  # The workspace that will be triggered
  workspace_id = tfe_workspace.application.id

  # The workspace whose successful apply triggers the above workspace
  sourceable_id = tfe_workspace.networking.id
}

# ─────────────────────────────────────────────────────────────────────────────
# Variable Set: shared variables across workspaces
# ─────────────────────────────────────────────────────────────────────────────

resource "tfe_variable_set" "platform_config" {
  name         = "Platform Configuration"
  description  = "Shared configuration variables for all platform workspaces"
  organization = var.organization
}

resource "tfe_variable" "region" {
  key             = "region"
  value           = "us-east-1"
  category        = "terraform"
  description     = "Default deployment region"
  variable_set_id = tfe_variable_set.platform_config.id
}

resource "tfe_variable" "environment" {
  key             = "environment"
  value           = "production"
  category        = "terraform"
  description     = "Deployment environment"
  variable_set_id = tfe_variable_set.platform_config.id
}

# Apply the variable set to both workspaces
resource "tfe_workspace_variable_set" "networking_vars" {
  variable_set_id = tfe_variable_set.platform_config.id
  workspace_id    = tfe_workspace.networking.id
}

resource "tfe_workspace_variable_set" "application_vars" {
  variable_set_id = tfe_variable_set.platform_config.id
  workspace_id    = tfe_workspace.application.id
}

# ─────────────────────────────────────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────────────────────────────────────

output "networking_workspace_id" {
  value       = tfe_workspace.networking.id
  description = "HCP Terraform workspace ID for networking"
}

output "application_workspace_id" {
  value       = tfe_workspace.application.id
  description = "HCP Terraform workspace ID for application"
}

output "run_trigger_id" {
  value       = tfe_workspace_run_trigger.app_depends_on_network.id
  description = "Run trigger ID — application triggers when networking applies"
}