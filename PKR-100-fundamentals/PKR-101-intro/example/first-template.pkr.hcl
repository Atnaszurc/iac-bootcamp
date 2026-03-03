# =============================================================================
# PKR-101: Introduction to Image Building — First Packer Template
#
# This is the simplest possible Packer template to introduce the core concepts:
#   - packer {}     block: plugin requirements
#   - variable {}   blocks: parameterize the build
#   - source {}     block: what to build (the "builder")
#   - build {}      block: what to do with it (provisioners + post-processors)
#
# Builder: hashicorp/null
#   The null builder doesn't create a real VM image — it connects via SSH
#   (or skips connection entirely with communicator = "none") and runs
#   provisioners. Perfect for learning Packer syntax without needing QEMU/KVM.
#
# Run:
#   packer init .
#   packer validate .
#   packer build first-template.pkr.hcl
# =============================================================================

# ─── Required plugins ────────────────────────────────────────────────────────
# The packer {} block declares which plugins this template needs.
# Packer downloads them automatically on `packer init`.

packer {
  required_version = ">= 1.14.0"

  required_plugins {
    # The null builder is built into Packer — no plugin needed.
    # We declare it explicitly here to show the pattern used by real builders.
  }
}

# ─── Variables ───────────────────────────────────────────────────────────────
# Variables make templates reusable. Override with:
#   packer build -var "image_name=my-image" .
#   packer build -var-file="prod.pkrvars.hcl" .

variable "image_name" {
  description = "Name for the output image"
  type        = string
  default     = "my-first-image"
}

variable "image_version" {
  description = "Version tag for the image"
  type        = string
  default     = "1.0.0"
}

variable "environment" {
  description = "Target environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ─── Locals ──────────────────────────────────────────────────────────────────
# Locals compute values from variables — like Terraform locals.

locals {
  # Build a consistent image tag: name-version-environment
  image_tag       = "${var.image_name}-${var.image_version}-${var.environment}"
  build_timestamp = formatdate("YYYY-MM-DD", timestamp())
}

# ─── Source block ────────────────────────────────────────────────────────────
# The source block defines HOW to create the base image.
# Format: source "<builder-type>" "<name>" { ... }
#
# In PKR-102 you'll use the "qemu" builder to build real VM images.
# Here we use "null" to focus on template structure without needing QEMU.

source "null" "example" {
  # communicator = "none" means: don't connect via SSH, just run local commands
  communicator = "none"
}

# ─── Build block ─────────────────────────────────────────────────────────────
# The build block defines WHAT to do with the source image.
# It references one or more sources and runs provisioners in order.

build {
  # Give this build a name (useful when building multiple sources)
  name = "pkr-101-intro"

  # Reference the source defined above
  # Format: "source.<builder-type>.<name>"
  sources = ["source.null.example"]

  # ── Provisioner 1: Shell (inline) ──────────────────────────────────────────
  # The shell provisioner runs commands inside the image during build.
  # inline = list of commands to run sequentially.

  provisioner "shell-local" {
    # shell-local runs on the HOST machine (not inside a VM).
    # Used here because the null builder has no VM to connect to.
    # In PKR-102 with the qemu builder, use "shell" instead.
    inline = [
      "echo '============================================'",
      "echo 'PKR-101: Building image: ${local.image_tag}'",
      "echo 'Build date: ${local.build_timestamp}'",
      "echo 'Environment: ${var.environment}'",
      "echo '============================================'",
      "echo 'Step 1: System update (simulated)'",
      "echo 'Step 2: Install packages (simulated)'",
      "echo 'Step 3: Configure application (simulated)'",
      "echo 'Step 4: Cleanup (simulated)'",
      "echo 'Build complete!'"
    ]
  }

  # ── Post-processor: Manifest ────────────────────────────────────────────────
  # Post-processors run AFTER the image is built.
  # The manifest post-processor writes a JSON file listing all built artifacts.

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true

    # Custom metadata added to the manifest
    custom_data = {
      image_name  = var.image_name
      version     = var.image_version
      environment = var.environment
      built_by    = "packer"
      course      = "PKR-101"
    }
  }
}