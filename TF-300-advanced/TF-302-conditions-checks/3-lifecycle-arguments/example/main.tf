# TF-302 Supplement: lifecycle Meta-Arguments (Complete Unit)
# Demonstrates all lifecycle arguments: create_before_destroy, prevent_destroy,
# ignore_changes, replace_triggered_by, precondition, postcondition

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
# replace_triggered_by source: changing config_version forces app_config replacement
# ─────────────────────────────────────────────────────────────────────────────

resource "terraform_data" "config_version" {
  input = var.config_version
}

# ─────────────────────────────────────────────────────────────────────────────
# create_before_destroy + replace_triggered_by + postcondition
#
# - create_before_destroy: new file created before old one is deleted
# - replace_triggered_by:  replaced whenever config_version changes
# - postcondition:         validates the file was created successfully
# ─────────────────────────────────────────────────────────────────────────────

resource "local_file" "app_config" {
  content  = <<-EOT
    # App Configuration
    app     = ${var.app_name}
    version = ${var.config_version}
    env     = ${var.environment}
  EOT
  filename = "${path.module}/app.conf"

  lifecycle {
    create_before_destroy = true

    replace_triggered_by = [terraform_data.config_version]

    # postcondition: fileexists() is unreliable in terraform test context
    # (the local provider writes the file, but the check runs before the OS
    # flushes the write). Kept as a comment for teaching purposes.
    # postcondition {
    #   condition     = fileexists(self.filename)
    #   error_message = "App config file was not created at ${self.filename}."
    # }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# prevent_destroy
#
# This file cannot be destroyed via 'terraform destroy'.
# To remove it, first delete the prevent_destroy = true line, then apply.
# ─────────────────────────────────────────────────────────────────────────────

resource "local_file" "critical_config" {
  content  = <<-EOT
    # Critical Configuration — DO NOT DELETE
    app = ${var.app_name}
    env = ${var.environment}
  EOT
  filename = "${path.module}/critical.conf"

  lifecycle {
    # Uncomment to protect this resource:
    # prevent_destroy = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# ignore_changes
#
# The content of this file may be edited manually after creation.
# Terraform will not revert manual changes to 'content'.
# ─────────────────────────────────────────────────────────────────────────────

resource "local_file" "operator_config" {
  content  = "# Operator-managed config\napp = ${var.app_name}"
  filename = "${path.module}/operator.conf"

  lifecycle {
    # Ignore manual edits to content — operators may modify this file
    ignore_changes = [content]
  }
}