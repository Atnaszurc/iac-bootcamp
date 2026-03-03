# =============================================================================
# PKR-104: Image Versioning — 04: Complete Lifecycle Management
#
# Demonstrates the full image lifecycle:
#   - Build phase: create image with full metadata
#   - Test phase: validate the image (smoke tests)
#   - Promote phase: mark image as ready for staging/prod
#   - Deprecate phase: mark old images for deletion
#
# Image lifecycle stages:
#   dev → staging → prod → deprecated
#
# Run:
#   # Build for dev
#   packer build -var "lifecycle_stage=dev" template.pkr.hcl
#
#   # Build for staging (after testing)
#   packer build -var "lifecycle_stage=staging" -var "promoted_from=dev" template.pkr.hcl
#
#   # Build for prod (after staging validation)
#   packer build -var "lifecycle_stage=prod" -var "promoted_from=staging" template.pkr.hcl
# =============================================================================

packer {
  required_version = ">= 1.14.0"
}

# ─── Variables ───────────────────────────────────────────────────────────────

variable "image_name" {
  description = "Base image name"
  type        = string
  default     = "ubuntu-app"
}

variable "image_version" {
  description = "Image version (SemVer)"
  type        = string
  default     = "1.0.0"
}

variable "lifecycle_stage" {
  description = "Current lifecycle stage: dev, staging, prod"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.lifecycle_stage)
    error_message = "lifecycle_stage must be one of: dev, staging, prod."
  }
}

variable "promoted_from" {
  description = "Previous lifecycle stage this image was promoted from"
  type        = string
  default     = ""
}

variable "approved_by" {
  description = "Person or system that approved this promotion"
  type        = string
  default     = "ci-system"
}

variable "change_ticket" {
  description = "Change management ticket reference (e.g. CHG-12345)"
  type        = string
  default     = ""
}

variable "retention_days" {
  description = "Number of days to retain this image before deletion"
  type        = number
  default     = 90
}

# ─── Locals ──────────────────────────────────────────────────────────────────

locals {
  build_timestamp = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
  build_date      = formatdate("YYYY-MM-DD", timestamp())

  # Versioned name includes lifecycle stage: ubuntu-app-1.0.0-prod
  artifact_name = "${var.image_name}-${var.image_version}-${var.lifecycle_stage}"

  # Retention date: build date + retention_days (approximated as months)
  # In production, calculate this properly in your CI/CD pipeline
  retention_note = "Retain for ${var.retention_days} days from ${local.build_date}"

  # Promotion chain: "" → dev → staging → prod
  promotion_chain = var.promoted_from != "" ? "${var.promoted_from} → ${var.lifecycle_stage}" : var.lifecycle_stage

  # Is this a production image?
  is_production = var.lifecycle_stage == "prod"
}

# ─── Source ──────────────────────────────────────────────────────────────────

source "null" "lifecycle_image" {
  communicator = "none"
}

# ─── Build ───────────────────────────────────────────────────────────────────

build {
  name    = local.artifact_name
  sources = ["source.null.lifecycle_image"]

  # Phase 1: Build
  provisioner "shell-local" {
    inline = [
      "echo '=== Lifecycle Management Demo ==='",
      "echo 'Artifact:       ${local.artifact_name}'",
      "echo 'Stage:          ${var.lifecycle_stage}'",
      "echo 'Promoted from:  ${var.promoted_from != "" ? var.promoted_from : "initial build"}'",
      "echo 'Promotion path: ${local.promotion_chain}'",
      "echo 'Approved by:    ${var.approved_by}'",
      "echo 'Change ticket:  ${var.change_ticket != "" ? var.change_ticket : "N/A"}'",
      "echo 'Retention:      ${local.retention_note}'",
      "echo 'Production:     ${local.is_production}'",
      "echo 'Built at:       ${local.build_timestamp}'",
      "echo '================================='",
    ]
  }

  # Phase 2: Smoke test (simulated)
  provisioner "shell-local" {
    inline = [
      "echo 'Running smoke tests...'",
      "echo 'Test 1: Image exists ✓'",
      "echo 'Test 2: Required packages installed ✓'",
      "echo 'Test 3: Services configured ✓'",
      "echo 'Test 4: Security hardening applied ✓'",
      "echo 'All smoke tests passed!'",
    ]
  }

  # Phase 3: Record lifecycle metadata
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      # Identity
      image_name    = var.image_name
      image_version = var.image_version
      artifact_name = local.artifact_name

      # Lifecycle
      lifecycle_stage  = var.lifecycle_stage
      promoted_from    = var.promoted_from
      promotion_chain  = local.promotion_chain
      is_production    = tostring(local.is_production)

      # Governance
      approved_by    = var.approved_by
      change_ticket  = var.change_ticket
      retention_days = tostring(var.retention_days)
      retention_note = local.retention_note

      # Audit
      build_timestamp = local.build_timestamp
      build_date      = local.build_date
      built_by        = "packer"
    }
  }
}