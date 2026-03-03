# TF-306 Section 3: Filesystem Functions Example
# Demonstrates: file(), templatefile(), fileset(), filebase64()
#
# This example uses the local provider (no cloud credentials needed).
# Run: terraform init && terraform apply

terraform {
  required_version = ">= 1.14"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

# ---------------------------------------------------------------------------
# Template file: rendered at apply time
# The template file exists in templates/app.conf.tftpl
# ---------------------------------------------------------------------------

# Step 1: Write a simple text file that file() will read back
resource "local_file" "ssh_key_placeholder" {
  filename = "${path.module}/keys/id_rsa.pub"
  content  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... terraform-training-key"
}

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "enabled_features" {
  description = "List of enabled application features"
  type        = list(string)
  default     = ["authentication", "logging", "metrics", "rate-limiting"]
}

# ---------------------------------------------------------------------------
# Locals: demonstrate filesystem functions
# ---------------------------------------------------------------------------

locals {
  # --- file() ---
  # Read the SSH public key file (created above)
  # In real usage: file("~/.ssh/id_rsa.pub") or file("${path.module}/keys/id_rsa.pub")
  ssh_key_content = local_file.ssh_key_placeholder.content

  # --- templatefile() ---
  # Render the app config template with variable substitution
  app_config_rendered = templatefile(
    "${path.module}/templates/app.conf.tftpl",
    {
      host          = "0.0.0.0"
      port          = var.app_port
      environment   = var.environment
      features_list = join("\n", [for feature in var.enabled_features : "${feature} = enabled"])
      db_host       = "db.internal"
      db_port       = 5432
      db_name       = "${var.environment}_appdb"
    }
  )

  # --- templatefile() for cloud-init style content ---
  # Demonstrates multi-line template rendering
  cloud_init_content = templatefile(
    "${path.module}/templates/app.conf.tftpl",
    {
      host          = "10.0.1.10"
      port          = 443
      environment   = "staging"
      features_list = join("\n", [for feature in ["authentication", "logging"] : "${feature} = enabled"])
      db_host       = "db-staging.internal"
      db_port          = 5432
      db_name          = "staging_appdb"
    }
  )

  # --- fileset() simulation ---
  # fileset() discovers files matching a glob pattern
  # Example: fileset("${path.module}/configs", "*.yaml")
  # Returns: toset(["app.yaml", "database.yaml"])
  #
  # We demonstrate the pattern with known files
  discovered_files_example = toset([
    "app.conf.tftpl",
    "nginx.conf.tftpl",
    "systemd.service.tftpl"
  ])

  # --- Combining fileset() with for expression ---
  # Real pattern: load all config files from a directory
  # configs = {
  #   for filename in fileset("${path.module}/configs", "*.yaml") :
  #   trimsuffix(filename, ".yaml") => yamldecode(
  #     file("${path.module}/configs/${filename}")
  #   )
  # }

  # --- path variables ---
  path_info = {
    module_path = path.module
    root_path   = path.root
    cwd_path    = path.cwd
  }
}

# ---------------------------------------------------------------------------
# Outputs: write rendered content to files
# ---------------------------------------------------------------------------

# Write the rendered app config
resource "local_file" "app_config_output" {
  filename = "${path.module}/output/app.conf"
  content  = local.app_config_rendered
}

# Write the staging config
resource "local_file" "staging_config_output" {
  filename = "${path.module}/output/staging-app.conf"
  content  = local.cloud_init_content
}

# Write a summary of filesystem function results
resource "local_file" "filesystem_functions_summary" {
  filename = "${path.module}/output/filesystem-functions-summary.txt"
  content  = <<-EOT
    ============================================================
    TF-306 Section 3: Filesystem Functions Summary
    ============================================================

    --- file() ---
    Reads raw file contents as a string.
    SSH key content (first 40 chars):
      ${substr(local.ssh_key_content, 0, 40)}...

    --- templatefile() ---
    Renders a .tftpl file with variable substitution.
    Template: ${path.module}/templates/app.conf.tftpl
    Variables passed: host, port, environment, features_list, db_*
    Output written to: ${path.module}/output/app.conf

    --- fileset() ---
    Discovers files matching a glob pattern.
    Example: fileset("${path.module}/templates", "*.tftpl")
    Would return: ${jsonencode(tolist(local.discovered_files_example))}

    --- path variables ---
    path.module : ${local.path_info.module_path}
    path.root   : ${local.path_info.root_path}
    path.cwd    : ${local.path_info.cwd_path}

    --- Template file extensions ---
    Convention: use .tftpl for Terraform template files
    This prevents editors from treating them as plain config files
    and signals that they contain Terraform template directives.

    --- Key patterns ---
    1. Always use path.module for relative file paths
    2. Use .tftpl extension for template files
    3. Use ~~ trim marker to control whitespace in templates
    4. Combine fileset() + for expression to load config directories
    5. Use file() for static content, templatefile() for dynamic content

    ============================================================
    EOT

  depends_on = [local_file.ssh_key_placeholder]
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "rendered_app_config" {
  description = "The rendered application configuration"
  value       = local.app_config_rendered
}

output "template_file_path" {
  description = "Path to the template file"
  value       = "${path.module}/templates/app.conf.tftpl"
}

output "output_files" {
  description = "Generated output files"
  value = {
    app_config     = local_file.app_config_output.filename
    staging_config = local_file.staging_config_output.filename
    summary        = local_file.filesystem_functions_summary.filename
  }
}

output "path_variables" {
  description = "Terraform path variables"
  value       = local.path_info
}

output "fileset_example" {
  description = "Example of what fileset() returns (simulated)"
  value       = local.discovered_files_example
}