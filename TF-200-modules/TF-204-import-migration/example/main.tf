# TF-204: Import & Migration Strategies
# ========================================
# This example demonstrates three key migration patterns:
#
#   1. IMPORT BLOCKS (Terraform 1.5+)
#      Declarative import — define what to import in code,
#      then run `terraform plan` to preview and `terraform apply` to import.
#
#   2. MOVED BLOCKS
#      Refactoring — rename resources or move them into/out of modules
#      without destroying and recreating them.
#
#   3. RESOURCE LIFECYCLE
#      prevent_destroy, ignore_changes — protect and stabilize resources
#      during and after migration.
#
# Uses the `local` provider so examples run anywhere without infrastructure.
# The local_file resource ID is the absolute file path.

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
# SECTION 1: Resources managed by Terraform (the "after" state)
# ─────────────────────────────────────────────────────────────────────────────
# These are the resources we want Terraform to manage.
# In a real migration, these would have been created manually first.

resource "local_file" "app_config" {
  filename        = "${path.module}/output/app.conf"
  file_permission = "0644"
  content         = <<-EOT
    # Application Configuration
    # Now managed by Terraform (imported from manual creation)
    app_name    = "${var.app_name}"
    environment = "${var.environment}"
    version     = "${var.app_version}"
  EOT

  # MIGRATION PATTERN: protect critical configs from accidental deletion
  lifecycle {
    prevent_destroy = true

    # MIGRATION PATTERN: ignore content changes during initial import
    # Remove this after validating the import is stable
    ignore_changes = [content]
  }
}

resource "local_file" "database_config" {
  filename        = "${path.module}/output/database.conf"
  file_permission = "0640"
  content         = <<-EOT
    # Database Configuration
    # Migrated to Terraform management
    host     = "${var.db_host}"
    port     = ${var.db_port}
    database = "${var.app_name}_${var.environment}"
  EOT
}

resource "local_file" "service_registry" {
  filename        = "${path.module}/output/services.json"
  file_permission = "0644"
  content = jsonencode({
    services = [
      for svc in var.services : {
        name    = svc
        enabled = true
        managed = "terraform"
      }
    ]
    metadata = {
      app         = var.app_name
      environment = var.environment
      migrated_at = "2025-01-01"
    }
  })
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2: IMPORT BLOCKS (Terraform 1.5+)
# ─────────────────────────────────────────────────────────────────────────────
# Import blocks tell Terraform: "this existing resource should be managed
# by this resource block". Run `terraform plan` to preview the import,
# then `terraform apply` to execute it.
#
# SYNTAX:
#   import {
#     to = <resource_address>
#     id = "<provider-specific-id>"
#   }
#
# For local_file, the ID is the absolute path to the file.
# These blocks are SAFE to leave in code — they are no-ops after import.
#
# NOTE: In this example the files are created by the resource blocks above,
# so the import blocks are commented out to avoid conflicts. In a real
# migration scenario, you would:
#   1. Create the resource block (without the file existing in state)
#   2. Add the import block pointing to the existing file
#   3. Run terraform plan → terraform apply
#   4. Remove the import block (optional — it's idempotent)

# import {
#   to = local_file.app_config
#   id = abspath("${path.module}/output/app.conf")
# }

# import {
#   to = local_file.database_config
#   id = abspath("${path.module}/output/database.conf")
# }

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 3: MOVED BLOCKS
# ─────────────────────────────────────────────────────────────────────────────
# Moved blocks handle refactoring — renaming resources or reorganizing code
# without destroying and recreating infrastructure.
#
# SYNTAX:
#   moved {
#     from = <old_resource_address>
#     to   = <new_resource_address>
#   }
#
# EXAMPLE SCENARIO: We renamed "app_settings" → "app_config" during refactoring.
# The moved block tells Terraform to update the state entry without touching
# the actual resource.
#
# NOTE: Moved blocks are also commented here because the old resource
# "local_file.app_settings" doesn't exist in this fresh example.
# In a real refactoring workflow:
#   1. Rename the resource block in code
#   2. Add a moved block from old name to new name
#   3. Run terraform plan → verify no destroy/create, only state rename
#   4. Run terraform apply
#   5. Remove the moved block after the next apply

# moved {
#   from = local_file.app_settings      # old name
#   to   = local_file.app_config        # new name
# }

# EXAMPLE: Moving a resource into a module
# moved {
#   from = local_file.app_config
#   to   = module.app_files.local_file.app_config
# }