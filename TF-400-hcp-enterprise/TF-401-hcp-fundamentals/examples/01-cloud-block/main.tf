# TF-401 Example: CLI-Driven Workspace with HCP Terraform
#
# This example demonstrates the `cloud` block for connecting
# a local Terraform configuration to HCP Terraform.
#
# Prerequisites:
#   1. Free HCP Terraform account at https://app.terraform.io
#   2. Run `terraform login` to authenticate
#   3. Create an organization named "my-organization" (or update below)
#   4. Run `terraform init` — HCP Terraform creates the workspace automatically
#
# NOTE: Update `organization` and workspace `name` before running.

terraform {
  required_version = ">= 1.14"

  # The `cloud` block replaces the `backend` block for HCP Terraform.
  # It configures CLI-driven remote execution and state storage.
  cloud {
    # Your HCP Terraform organization name
    organization = "my-organization"

    workspaces {
      # The workspace name — created automatically on first `terraform init`
      name = "tf-401-demo"
    }
  }

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

# Simple resource to demonstrate remote execution
# When you run `terraform apply`, this runs in HCP Terraform's infrastructure
resource "local_file" "hello" {
  content  = "Hello from HCP Terraform! Run ID: ${terraform.workspace}"
  filename = "${path.module}/output/hello.txt"
}

resource "local_file" "workspace_info" {
  content = jsonencode({
    workspace   = terraform.workspace
    description = "This file was created by a remote run in HCP Terraform"
    timestamp   = "See run history in HCP Terraform UI"
  })
  filename = "${path.module}/output/workspace-info.json"
}