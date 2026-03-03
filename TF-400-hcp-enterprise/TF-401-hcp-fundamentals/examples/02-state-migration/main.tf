# TF-401 Example: Migrating Local State to HCP Terraform
#
# This example shows the BEFORE and AFTER of migrating from
# a local backend to HCP Terraform.
#
# MIGRATION STEPS:
# ================
# Step 1: You have existing Terraform with local state (no backend block)
# Step 2: Add the `cloud` block (shown below)
# Step 3: Run `terraform init`
#         Terraform detects existing local state and asks:
#         "Would you like to copy existing state to the new backend? [yes/no]"
# Step 4: Type "yes" — state is uploaded to HCP Terraform
# Step 5: Delete local .tfstate files (they are no longer needed)
#
# NOTE: Update `organization` and workspace `name` before running.

# ─────────────────────────────────────────────────────────────────────────────
# BEFORE (local state — no backend block):
# ─────────────────────────────────────────────────────────────────────────────
# terraform {
#   required_version = ">= 1.14"
#   required_providers {
#     local = { source = "hashicorp/local", version = "~> 2.7" }
#   }
# }
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# AFTER (HCP Terraform — add the cloud block):
# ─────────────────────────────────────────────────────────────────────────────
terraform {
  required_version = ">= 1.14"

  cloud {
    organization = "my-organization"

    workspaces {
      name = "tf-401-migrated"
    }
  }

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

# This resource already existed before migration.
# After migration, its state is now managed by HCP Terraform.
resource "local_file" "config" {
  content  = "This resource was migrated from local state to HCP Terraform."
  filename = "${path.module}/output/config.txt"
}

resource "local_file" "migration_record" {
  content = jsonencode({
    migrated_at = "See HCP Terraform run history"
    from        = "local state (.tfstate file)"
    to          = "HCP Terraform remote state"
    workspace   = "tf-401-migrated"
    benefit     = "State is now encrypted, versioned, and team-accessible"
  })
  filename = "${path.module}/output/migration-record.json"
}