# TF-204 Supplement: removed blocks (Terraform 1.7+)
# Demonstrates removing resources from state without destroying them

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
# STEP 1 (Initial state): Both resources managed by Terraform
# Apply this first, then switch to STEP 2 to demonstrate removed blocks
# ─────────────────────────────────────────────────────────────────────────────

# Uncomment for STEP 1 (initial apply):
# resource "local_file" "handoff_config" {
#   content  = "# Config handed off to another team\nenv = staging"
#   filename = "${path.module}/handoff.conf"
# }

# resource "local_file" "permanent_config" {
#   content  = "# Always managed by Terraform\nenv = production"
#   filename = "${path.module}/permanent.conf"
# }

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 (After handoff): Remove handoff_config from state, keep permanent
#
# The 'removed' block tells Terraform:
#   "Stop tracking this resource, but DO NOT destroy it"
#
# After running 'terraform apply':
#   - handoff.conf still exists on disk
#   - Terraform no longer manages it
#   - permanent.conf is still managed normally
# ─────────────────────────────────────────────────────────────────────────────

removed {
  from = local_file.handoff_config

  lifecycle {
    destroy = false  # Keep the file, just stop tracking it in state
  }
}

resource "local_file" "permanent_config" {
  content  = "# Always managed by Terraform\nenv = production"
  filename = "${path.module}/permanent.conf"
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 (Cleanup): After apply, delete the 'removed' block above
# The removed block has served its purpose — clean it up
# ─────────────────────────────────────────────────────────────────────────────