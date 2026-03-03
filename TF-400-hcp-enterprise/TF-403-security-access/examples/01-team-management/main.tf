# TF-403 Example: Team Management & Access Control
#
# This example uses the `tfe` provider to configure teams, permissions,
# and variable sets in HCP Terraform (meta-Terraform).
#
# This demonstrates the "manage HCP Terraform with Terraform" pattern —
# your HCP Terraform configuration is itself managed as code.
#
# Prerequisites:
#   - HCP Terraform organization
#   - TFE_TOKEN environment variable (organization owner token)
#   - Workspaces already created (or create them here)

terraform {
  required_version = ">= 1.14"

  required_providers {
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

variable "workspace_name" {
  type        = string
  description = "Name of the workspace to manage access for"
  default     = "production-app"
}

# ─────────────────────────────────────────────────────────────────────────────
# Teams
# ─────────────────────────────────────────────────────────────────────────────

# Platform team — manages infrastructure, has broad organization access
resource "tfe_team" "platform" {
  name         = "platform-team"
  organization = var.organization

  organization_access {
    manage_workspaces = true
    manage_policies   = false  # Only owners manage policies
    manage_vcs_settings = true
    read_workspaces   = true
    read_projects     = true
  }
}

# Developer team — can plan and apply their workspaces
resource "tfe_team" "developers" {
  name         = "developers"
  organization = var.organization

  # No organization-level permissions
  # Access is granted at the workspace level below
}

# Read-only team — auditors, stakeholders
resource "tfe_team" "readonly" {
  name         = "read-only"
  organization = var.organization

  organization_access {
    read_workspaces = true
    read_projects   = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Workspace Access
# ─────────────────────────────────────────────────────────────────────────────

# Reference an existing workspace
data "tfe_workspace" "app" {
  name         = var.workspace_name
  organization = var.organization
}

# Platform team gets admin access to all workspaces
resource "tfe_team_access" "platform_admin" {
  access       = "admin"
  team_id      = tfe_team.platform.id
  workspace_id = data.tfe_workspace.app.id
}

# Developers get write access (can plan and apply)
resource "tfe_team_access" "dev_write" {
  access       = "write"
  team_id      = tfe_team.developers.id
  workspace_id = data.tfe_workspace.app.id
}

# Read-only team gets read access (can view state and runs)
resource "tfe_team_access" "readonly_read" {
  access       = "read"
  team_id      = tfe_team.readonly.id
  workspace_id = data.tfe_workspace.app.id
}

# ─────────────────────────────────────────────────────────────────────────────
# Variable Sets — shared configuration
# ─────────────────────────────────────────────────────────────────────────────

# Shared non-sensitive configuration
resource "tfe_variable_set" "platform_config" {
  name         = "Platform Configuration"
  description  = "Shared non-sensitive configuration for all workspaces"
  organization = var.organization
  global       = false  # Not applied globally — applied per workspace below
}

resource "tfe_variable" "region" {
  key             = "region"
  value           = "us-east-1"
  category        = "terraform"
  description     = "Default AWS region"
  sensitive       = false
  variable_set_id = tfe_variable_set.platform_config.id
}

resource "tfe_variable" "environment" {
  key             = "environment"
  value           = "production"
  category        = "terraform"
  description     = "Deployment environment"
  sensitive       = false
  variable_set_id = tfe_variable_set.platform_config.id
}

# Apply variable set to the workspace
resource "tfe_workspace_variable_set" "app_config" {
  variable_set_id = tfe_variable_set.platform_config.id
  workspace_id    = data.tfe_workspace.app.id
}

# ─────────────────────────────────────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────────────────────────────────────

output "platform_team_id" {
  value       = tfe_team.platform.id
  description = "Platform team ID"
}

output "developers_team_id" {
  value       = tfe_team.developers.id
  description = "Developers team ID"
}

output "variable_set_id" {
  value       = tfe_variable_set.platform_config.id
  description = "Platform configuration variable set ID"
}