# ============================================================================
# GCP-201: Setup & Authentication - Terraform Tests with Mock Provider
# ============================================================================
# Uses mock_provider to test configuration without real GCP credentials.
# Validates provider configuration, variable defaults, and output structure.

mock_provider "google" {}

# Basic test for GCP-201 example
# Tests provider configuration and Cloud Storage bucket creation

variables {
  project_id  = "test-project-12345"
  region      = "us-central1"
  zone        = "us-central1-a"
  environment = "dev"
}

run "validate_provider_configuration" {
  command = plan

  assert {
    condition     = var.project_id == "test-project-12345"
    error_message = "Project ID should be test-project-12345"
  }

  assert {
    condition     = var.region == "us-central1"
    error_message = "Region should be us-central1"
  }

  assert {
    condition     = var.zone == "us-central1-a"
    error_message = "Zone should be us-central1-a"
  }
}

run "validate_bucket_configuration" {
  command = plan

  assert {
    condition     = google_storage_bucket.example.location == "US"
    error_message = "Bucket location should be US"
  }

  assert {
    condition     = google_storage_bucket.example.storage_class == "STANDARD"
    error_message = "Bucket storage class should be STANDARD"
  }

  assert {
    condition     = google_storage_bucket.example.uniform_bucket_level_access == true
    error_message = "Uniform bucket-level access should be enabled"
  }

  assert {
    condition     = google_storage_bucket.example.public_access_prevention == "enforced"
    error_message = "Public access prevention should be enforced"
  }

  assert {
    condition     = google_storage_bucket.example.force_destroy == true
    error_message = "Force destroy should be enabled for training"
  }
}

run "validate_api_enablement" {
  command = plan

  assert {
    condition     = google_project_service.compute.service == "compute.googleapis.com"
    error_message = "Compute API should be enabled"
  }

  assert {
    condition     = google_project_service.storage.service == "storage.googleapis.com"
    error_message = "Storage API should be enabled"
  }

  assert {
    condition     = google_project_service.compute.disable_on_destroy == false
    error_message = "APIs should not be disabled on destroy"
  }
}

run "validate_labels" {
  command = plan

  assert {
    condition     = contains(keys(google_storage_bucket.example.labels), "managed_by")
    error_message = "Bucket should have managed_by label"
  }

  assert {
    condition     = contains(keys(google_storage_bucket.example.labels), "environment")
    error_message = "Bucket should have environment label"
  }

  assert {
    condition     = google_storage_bucket.example.labels["environment"] == var.environment
    error_message = "Environment label should match variable"
  }
}

run "validate_lifecycle_rule" {
  command = plan

  assert {
    condition     = length(google_storage_bucket.example.lifecycle_rule) > 0
    error_message = "Bucket should have at least one lifecycle rule"
  }

  assert {
    condition     = length([for rule in google_storage_bucket.example.lifecycle_rule : rule if length([for c in rule.condition : c if c.age == 30]) > 0]) > 0
    error_message = "Lifecycle rule should delete objects after 30 days"
  }

  assert {
    condition     = length([for rule in google_storage_bucket.example.lifecycle_rule : rule if length([for a in rule.action : a if a.type == "Delete"]) > 0]) > 0
    error_message = "Lifecycle rule action should be Delete"
  }
}

run "validate_bucket_object" {
  command = plan

  assert {
    condition     = google_storage_bucket_object.readme.name == "README.txt"
    error_message = "Bucket object should be named README.txt"
  }

  assert {
    condition     = google_storage_bucket_object.readme.content_type == "text/plain"
    error_message = "Bucket object content type should be text/plain"
  }

  assert {
    condition     = google_storage_bucket_object.readme.bucket == google_storage_bucket.example.name
    error_message = "Bucket object should be in the example bucket"
  }
}

run "validate_outputs" {
  command = plan

  assert {
    condition     = output.project_id == var.project_id
    error_message = "Output project_id should match input variable"
  }

  assert {
    condition     = output.region == var.region
    error_message = "Output region should match input variable"
  }

  assert {
    condition     = output.zone == var.zone
    error_message = "Output zone should match input variable"
  }

  assert {
    condition     = output.bucket_name == google_storage_bucket.example.name
    error_message = "Output bucket_name should match created bucket"
  }

  assert {
    condition     = length(output.enabled_apis) == 2
    error_message = "Should have 2 enabled APIs"
  }
}