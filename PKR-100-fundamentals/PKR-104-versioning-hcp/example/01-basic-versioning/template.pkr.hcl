# =============================================================================
# PKR-104: Image Versioning — 01: Basic Versioning
#
# Demonstrates the simplest versioning approach:
#   - Pass version as a variable at build time
#   - Embed version in the image name and metadata
#   - Write a manifest with version information
#
# Run:
#   packer init .
#   packer build -var "version=1.2.3" template.pkr.hcl
# =============================================================================

packer {
  required_version = ">= 1.14.0"
}

# ─── Variables ───────────────────────────────────────────────────────────────

variable "image_name" {
  description = "Base name for the image"
  type        = string
  default     = "ubuntu-base"
}

variable "version" {
  description = "Image version (set at build time, e.g. from CI/CD)"
  type        = string
  default     = "1.0.0"
}

variable "environment" {
  description = "Target environment"
  type        = string
  default     = "dev"
}

# ─── Locals ──────────────────────────────────────────────────────────────────

locals {
  # Versioned image name: ubuntu-base-1.0.0
  versioned_name  = "${var.image_name}-${var.version}"

  # Full artifact name includes environment: ubuntu-base-1.0.0-dev
  artifact_name   = "${var.image_name}-${var.version}-${var.environment}"

  # Build timestamp for traceability
  build_timestamp = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
}

# ─── Source ──────────────────────────────────────────────────────────────────
# Using null builder for demonstration — replace with qemu for real builds

source "null" "versioned_image" {
  communicator = "none"
}

# ─── Build ───────────────────────────────────────────────────────────────────

build {
  name    = local.versioned_name
  sources = ["source.null.versioned_image"]

  provisioner "shell-local" {
    inline = [
      "echo '=== Basic Versioning Demo ==='",
      "echo 'Image name:    ${local.versioned_name}'",
      "echo 'Artifact:      ${local.artifact_name}'",
      "echo 'Version:       ${var.version}'",
      "echo 'Environment:   ${var.environment}'",
      "echo 'Built at:      ${local.build_timestamp}'",
      "echo '==========================='",
    ]
  }

  # Manifest records the build output with version metadata
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      image_name      = var.image_name
      version         = var.version
      environment     = var.environment
      artifact_name   = local.artifact_name
      build_timestamp = local.build_timestamp
    }
  }
}