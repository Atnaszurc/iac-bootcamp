terraform {
  required_version = ">= 1.15.0"
}

# Simple configuration module for demonstrating dynamic module sources
resource "terraform_data" "config" {
  input = {
    app_name    = var.app_name
    environment = var.environment
    version_tag = var.version_tag
    timestamp   = timestamp()
  }
}

# Simulate configuration file creation
resource "terraform_data" "config_file" {
  input = jsonencode({
    application = var.app_name
    environment = var.environment
    version     = var.version_tag
    settings = {
      debug_mode = var.environment == "dev"
      log_level  = var.environment == "prod" ? "error" : "debug"
    }
  })
}