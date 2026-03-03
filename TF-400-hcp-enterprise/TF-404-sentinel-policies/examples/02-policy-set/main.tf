# TF-404 Example: Policy Set Configuration
#
# This example configures a Sentinel policy set in HCP Terraform
# using the `tfe` provider (meta-Terraform).
#
# A policy set is a collection of Sentinel policies that can be
# applied to specific workspaces or globally to all workspaces.
#
# Prerequisites:
#   - HCP Terraform Plus or Business tier (Sentinel requires paid tier)
#   - TFE_TOKEN environment variable (organization owner token)
#   - VCS connection configured (for VCS-connected policy sets)

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

variable "workspace_id" {
  type        = string
  description = "Workspace ID to apply the policy set to"
}

# ─────────────────────────────────────────────────────────────────────────────
# Sentinel Policies (inline — for simple policies)
# ─────────────────────────────────────────────────────────────────────────────

# Policy 1: Restrict VM memory in non-production workspaces
resource "tfe_sentinel_policy" "restrict_memory" {
  name         = "restrict-vm-memory"
  description  = "Prevents VMs > 4GB RAM in non-production workspaces"
  organization = var.organization

  # Policy content inline (alternatively, use a VCS-connected policy set)
  policy = <<-SENTINEL
    import "tfplan/v2" as tfplan
    import "tfrun"

    max_memory_mb = 4096

    is_production = rule {
      tfrun.workspace.name contains "production"
    }

    vms = filter tfplan.resource_changes as _, rc {
      rc.type is "libvirt_domain" and
      rc.mode is "managed" and
      rc.change.actions contains "create"
    }

    memory_within_limit = rule when not is_production {
      all vms as _, vm {
        int(vm.change.after.memory) <= max_memory_mb
      }
    }

    main = rule { memory_within_limit }
  SENTINEL

  # soft-mandatory: blocks apply but workspace admins can override
  enforce_mode = "soft-mandatory"
}

# Policy 2: Require resource naming convention
resource "tfe_sentinel_policy" "naming_convention" {
  name         = "require-naming-convention"
  description  = "All VMs must follow the naming convention: <env>-<role>-<number>"
  organization = var.organization

  policy = <<-SENTINEL
    import "tfplan/v2" as tfplan

    # Regex: environment-role-number (e.g., dev-web-01, prod-db-02)
    naming_pattern = "^(dev|staging|prod)-[a-z]+-[0-9]+$"

    vms = filter tfplan.resource_changes as _, rc {
      rc.type is "libvirt_domain" and
      rc.mode is "managed" and
      rc.change.actions contains "create"
    }

    valid_names = rule {
      all vms as _, vm {
        vm.change.after.name matches naming_pattern
      }
    }

    main = rule { valid_names }
  SENTINEL

  # advisory: warns but doesn't block (good for gradual rollout)
  enforce_mode = "advisory"
}

# ─────────────────────────────────────────────────────────────────────────────
# Policy Set — groups policies and applies them to workspaces
# ─────────────────────────────────────────────────────────────────────────────

resource "tfe_policy_set" "infrastructure_policies" {
  name         = "infrastructure-policies"
  description  = "Core infrastructure governance policies"
  organization = var.organization
  kind         = "sentinel"

  # Apply to specific workspaces (not globally)
  global = false

  # Link individual policies to this set
  policy_ids = [
    tfe_sentinel_policy.restrict_memory.id,
    tfe_sentinel_policy.naming_convention.id,
  ]

  # Apply to the specified workspace
  workspace_ids = [var.workspace_id]
}

# ─────────────────────────────────────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────────────────────────────────────

output "policy_set_id" {
  value       = tfe_policy_set.infrastructure_policies.id
  description = "Policy set ID"
}

output "restrict_memory_policy_id" {
  value       = tfe_sentinel_policy.restrict_memory.id
  description = "Restrict memory policy ID"
}