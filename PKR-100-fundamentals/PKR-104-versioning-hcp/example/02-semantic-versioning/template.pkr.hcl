# =============================================================================
# PKR-104: Image Versioning — 02: Semantic Versioning
#
# Demonstrates semantic versioning (SemVer: MAJOR.MINOR.PATCH) for images:
#   - Separate major/minor/patch variables
#   - Computed full version string
#   - Pre-release and build metadata support
#   - Version validation
#
# SemVer rules:
#   MAJOR: Breaking changes (incompatible API changes)
#   MINOR: New features (backward compatible)
#   PATCH: Bug fixes (backward compatible)
#
# Run:
#   packer build -var "major=2" -var "minor=1" -var "patch=0" template.pkr.hcl
#   packer build -var "pre_release=rc.1" template.pkr.hcl
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

variable "major" {
  description = "Major version number (increment for breaking changes)"
  type        = number
  default     = 1
}

variable "minor" {
  description = "Minor version number (increment for new features)"
  type        = number
  default     = 0
}

variable "patch" {
  description = "Patch version number (increment for bug fixes)"
  type        = number
  default     = 0
}

variable "pre_release" {
  description = "Pre-release identifier (e.g. alpha.1, beta.2, rc.1). Empty = stable release."
  type        = string
  default     = ""
}

variable "build_number" {
  description = "CI/CD build number for traceability (e.g. from $CI_PIPELINE_ID)"
  type        = string
  default     = "local"
}

variable "git_commit" {
  description = "Git commit SHA for traceability (e.g. from $CI_COMMIT_SHORT_SHA)"
  type        = string
  default     = "unknown"
}

# ─── Locals ──────────────────────────────────────────────────────────────────

locals {
  # Core SemVer string: 1.0.0
  semver_core = "${var.major}.${var.minor}.${var.patch}"

  # Full SemVer: 1.0.0 or 1.0.0-rc.1
  semver_full = var.pre_release != "" ? "${local.semver_core}-${var.pre_release}" : local.semver_core

  # Image name with version: ubuntu-base-1.0.0
  versioned_name = "${var.image_name}-${local.semver_full}"

  # Build metadata (not part of SemVer precedence, but useful for tracing)
  # Format: ubuntu-base-1.0.0+build.42.abc1234
  artifact_with_meta = "${local.versioned_name}+build.${var.build_number}.${var.git_commit}"

  # Is this a stable release? (no pre-release suffix)
  is_stable = var.pre_release == ""

  build_timestamp = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
}

# ─── Source ──────────────────────────────────────────────────────────────────

source "null" "semver_image" {
  communicator = "none"
}

# ─── Build ───────────────────────────────────────────────────────────────────

build {
  name    = local.versioned_name
  sources = ["source.null.semver_image"]

  provisioner "shell-local" {
    inline = [
      "echo '=== Semantic Versioning Demo ==='",
      "echo 'SemVer core:   ${local.semver_core}'",
      "echo 'SemVer full:   ${local.semver_full}'",
      "echo 'Image name:    ${local.versioned_name}'",
      "echo 'With metadata: ${local.artifact_with_meta}'",
      "echo 'Stable:        ${local.is_stable}'",
      "echo 'Build #:       ${var.build_number}'",
      "echo 'Git commit:    ${var.git_commit}'",
      "echo 'Built at:      ${local.build_timestamp}'",
      "echo '================================'",
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      image_name      = var.image_name
      semver          = local.semver_full
      major           = tostring(var.major)
      minor           = tostring(var.minor)
      patch           = tostring(var.patch)
      pre_release     = var.pre_release
      is_stable       = tostring(local.is_stable)
      build_number    = var.build_number
      git_commit      = var.git_commit
      build_timestamp = local.build_timestamp
    }
  }
}