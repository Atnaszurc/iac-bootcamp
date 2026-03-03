# TF-101 Section 4: null_resource vs terraform_data
# Demonstrates the legacy null_resource and modern terraform_data patterns

terraform {
  required_version = ">= 1.14"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
    # null provider shown for comparison — not needed with terraform_data
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# ============================================================
# PART 1: null_resource (Legacy — you'll see this in the wild)
# ============================================================

# Legacy pattern: null_resource with triggers
# Still works, but terraform_data is preferred for new code
resource "null_resource" "legacy_example" {
  triggers = {
    # Re-run when this value changes
    config_version = var.app_version
  }

  provisioner "local-exec" {
    command = "echo '[LEGACY] null_resource triggered for version ${self.triggers.config_version}'"
  }
}

# ============================================================
# PART 2: terraform_data (Modern — Terraform 1.4+)
# ============================================================

# Create a config file that we'll track
resource "local_file" "app_config" {
  content  = <<-EOT
    # Application Configuration
    environment = "${var.environment}"
    version     = "${var.app_version}"
  EOT
  filename = "${path.module}/app.conf"
}

# Modern pattern: terraform_data with triggers_replace
resource "terraform_data" "config_tracker" {
  # triggers_replace accepts any type (not just a map like null_resource)
  triggers_replace = {
    version     = var.app_version
    environment = var.environment
  }

  provisioner "local-exec" {
    command = "echo '[MODERN] terraform_data triggered for ${var.environment} v${var.app_version}' >> deploy-log.txt"
  }

  # Runs on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "echo '[MODERN] Cleaning up deployment' >> deploy-log.txt"
  }
}

# terraform_data with input/output — store computed values
resource "terraform_data" "deployment_info" {
  # input stores arbitrary data, accessible as self.output
  input = {
    environment = var.environment
    version     = var.app_version
    config_file = local_file.app_config.filename
    deployed_at = timestamp()
  }
}

# terraform_data with a simple scalar trigger (not a map)
resource "terraform_data" "always_log" {
  # timestamp() changes on every apply — always triggers
  triggers_replace = timestamp()

  provisioner "local-exec" {
    command     = "echo '[INFO] Apply ran at ${timestamp()}' >> deploy-log.txt"
    working_dir = path.module
  }
}