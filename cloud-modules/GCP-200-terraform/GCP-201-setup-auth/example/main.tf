# GCP-201: Setup & Authentication
# Demonstrates: GCP provider configuration, authentication methods
# Provider: hashicorp/google
# Run: terraform init && terraform plan
#
# Prerequisites:
#   - gcloud CLI installed and configured (gcloud auth application-default login)
#   - OR environment variable: GOOGLE_APPLICATION_CREDENTIALS
#   - OR service account key file
#
# See: https://registry.terraform.io/providers/hashicorp/google/latest/docs

terraform {
  required_version = ">= 1.14"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.24.0"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider configuration
# Authentication is resolved in this order:
#   1. GOOGLE_APPLICATION_CREDENTIALS environment variable
#   2. gcloud auth application-default login
#   3. Service account key file
# ─────────────────────────────────────────────────────────────────────────────

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"

  disable_on_destroy = false
}

# Data source to get current project information
data "google_project" "current" {
  project_id = var.project_id
}

# Simple Cloud Storage bucket to demonstrate provider configuration
resource "google_storage_bucket" "example" {
  name          = "${var.project_id}-gcp-201-example"
  location      = "US"
  storage_class = "STANDARD"

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  # Public access prevention
  public_access_prevention = "enforced"

  # Labels
  labels = merge(
    var.labels,
    {
      environment = var.environment
    }
  )

  # Lifecycle rule to demonstrate configuration
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  # Force destroy for easy cleanup in training
  force_destroy = true

  depends_on = [google_project_service.storage]
}

# Upload a sample object
resource "google_storage_bucket_object" "readme" {
  name    = "README.txt"
  bucket  = google_storage_bucket.example.name
  content = <<-EOT
    # GCP-201 Example Bucket
    
    This bucket was created as part of the GCP-201 training module.
    
    Project: ${var.project_id}
    Region: ${var.region}
    Environment: ${var.environment}
    
    Created by Terraform on ${timestamp()}
  EOT

  content_type = "text/plain"
}