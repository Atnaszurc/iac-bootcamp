# TF-101 Example: Hello World with Terraform
# This example demonstrates basic Terraform concepts

terraform {
  required_version = ">= 1.14"
  
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

provider "local" {}

# Example 1: Simple file creation
resource "local_file" "hello" {
  content  = "Hello, Terraform! This is my first infrastructure as code."
  filename = "${path.module}/hello.txt"
}

# Example 2: Multi-line content with heredoc
resource "local_file" "info" {
  content  = <<-EOT
    Terraform Training
    ==================
    Course: TF-101
    Topic: Introduction to IaC & Terraform Basics
    
    This file was created by Terraform!
    Timestamp: ${timestamp()}
  EOT
  filename = "${path.module}/info.txt"
}

# Example 3: Configuration file
resource "local_file" "config" {
  content  = <<-EOT
    # Application Configuration
    app_name = "terraform-training"
    version  = "1.0.0"
    environment = "development"
    
    # Features
    enable_logging = true
    enable_metrics = true
  EOT
  filename = "${path.module}/app-config.txt"
}

# Output: Display file IDs
output "hello_file_id" {
  description = "ID of the hello.txt file"
  value       = local_file.hello.id
}

output "info_file_id" {
  description = "ID of the info.txt file"
  value       = local_file.info.id
}

output "config_file_id" {
  description = "ID of the config file"
  value       = local_file.config.id
}

output "all_files" {
  description = "List of all created files"
  value = [
    local_file.hello.filename,
    local_file.info.filename,
    local_file.config.filename
  ]
}