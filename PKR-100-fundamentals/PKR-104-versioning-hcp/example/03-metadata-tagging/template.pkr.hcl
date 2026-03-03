# =============================================================================
# PKR-104: Image Versioning — 03: Rich Metadata & Tagging
#
# Demonstrates comprehensive metadata strategies:
#   - Structured metadata in manifest
#   - Compliance and audit tags
#   - Image lineage tracking (base image reference)
#   - Environment promotion tracking
#
# Run:
#   packer build template.pkr.hcl
#   packer build -var "base_image_version=22.04" -var "app_version=3.1.0" template.pkr.hcl
# =============================================================================

packer {
  required_version = ">= 1.14.0"
}

# ─── Variables ───────────────────────────────────────────────────────────────

variable "image_name" {
  description = "Image name"
  type        = string
  default     = "ubuntu-app"
}

variable "image_version" {
  description = "Image version"
  type        = string
  default     = "1.0.0"
}

variable "base_image_name" {
  description = "Name of the base image this was built from (lineage tracking)"
  type        = string
  default     = "ubuntu-base"
}

variable "base_image_version" {
  description = "Version of the base image (lineage tracking)"
  type        = string
  default     = "22.04"
}

variable "app_name" {
  description = "Application installed in this image"
  type        = string
  default     = "my-app"
}

variable "app_version" {
  description = "Version of the application installed"
  type        = string
  default     = "1.0.0"
}

variable "team" {
  description = "Team responsible for this image"
  type        = string
  default     = "platform"
}

variable "cost_center" {
  description = "Cost center for billing attribution"
  type        = string
  default     = "engineering"
}

variable "compliance_level" {
  description = "Compliance level (standard, pci, hipaa, sox)"
  type        = string
  default     = "standard"
}

# ─── Locals ──────────────────────────────────────────────────────────────────

locals {
  build_timestamp = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
  build_date      = formatdate("YYYY-MM-DD", timestamp())

  # Structured metadata — mirrors what you'd set as cloud provider tags
  metadata = {
    # Identity
    "Name"              = "${var.image_name}-${var.image_version}"
    "Version"           = var.image_version
    "ImageFamily"       = var.image_name

    # Lineage — track what this image was built from
    "BaseImage"         = var.base_image_name
    "BaseImageVersion"  = var.base_image_version

    # Application
    "AppName"           = var.app_name
    "AppVersion"        = var.app_version

    # Ownership
    "Team"              = var.team
    "CostCenter"        = var.cost_center
    "ManagedBy"         = "packer"

    # Compliance & audit
    "ComplianceLevel"   = var.compliance_level
    "BuildDate"         = local.build_date
    "BuildTimestamp"    = local.build_timestamp

    # Lifecycle — updated during promotion
    "Status"            = "dev"
    "PromotedToStaging" = "false"
    "PromotedToProd"    = "false"
  }
}

# ─── Source ──────────────────────────────────────────────────────────────────

source "null" "metadata_image" {
  communicator = "none"
}

# ─── Build ───────────────────────────────────────────────────────────────────

build {
  name    = "${var.image_name}-${var.image_version}"
  sources = ["source.null.metadata_image"]

  provisioner "shell-local" {
    inline = [
      "echo '=== Metadata & Tagging Demo ==='",
      "echo 'Image:         ${var.image_name}-${var.image_version}'",
      "echo 'Base image:    ${var.base_image_name}:${var.base_image_version}'",
      "echo 'App:           ${var.app_name}:${var.app_version}'",
      "echo 'Team:          ${var.team}'",
      "echo 'Compliance:    ${var.compliance_level}'",
      "echo 'Built at:      ${local.build_timestamp}'",
      "echo '==============================='",
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = local.metadata
  }
}