# GCP-203: Security & Storage
# Demonstrates: IAM, service accounts, Cloud KMS, Cloud Storage, persistent disks, Secret Manager
# Provider: hashicorp/google
# Run: terraform init && terraform apply
#
# Prerequisites: GCP credentials configured (see GCP-201)

terraform {
  required_version = ">= 1.14"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.24.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider configuration
# ─────────────────────────────────────────────────────────────────────────────

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com",
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================================
# IAM & Service Accounts
# ============================================================================

# Service account for application
resource "google_service_account" "app_sa" {
  account_id   = var.service_account_name
  display_name = "Application Service Account"
  description  = "Service account for GCP-203 training application"

  depends_on = [google_project_service.required_apis]
}

# Custom IAM role
resource "google_project_iam_custom_role" "app_role" {
  role_id     = "appCustomRole${random_id.suffix.hex}"
  title       = "Application Custom Role"
  description = "Custom role for application with specific permissions"

  permissions = [
    "compute.instances.get",
    "compute.instances.list",
    "storage.buckets.get",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.create",
  ]

  depends_on = [google_project_service.required_apis]
}

# Bind custom role to service account
resource "google_project_iam_member" "app_sa_custom_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.app_role.id
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

# Grant Compute Viewer role
resource "google_project_iam_member" "app_sa_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

# ============================================================================
# Cloud KMS
# ============================================================================

# KMS key ring
resource "google_kms_key_ring" "keyring" {
  count    = var.enable_kms ? 1 : 0
  name     = "gcp-203-keyring-${random_id.suffix.hex}"
  location = var.region

  depends_on = [google_project_service.required_apis]
}

# KMS crypto key
resource "google_kms_crypto_key" "key" {
  count           = var.enable_kms ? 1 : 0
  name            = "gcp-203-key"
  key_ring        = google_kms_key_ring.keyring[0].id
  rotation_period = var.kms_key_rotation_period

  lifecycle {
    prevent_destroy = false # Set to true in production
  }

  labels = var.labels
}

# Grant KMS permissions to service account
resource "google_kms_crypto_key_iam_member" "crypto_key" {
  count         = var.enable_kms ? 1 : 0
  crypto_key_id = google_kms_crypto_key.key[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.app_sa.email}"
}

# ============================================================================
# Cloud Storage
# ============================================================================

# Standard bucket
resource "google_storage_bucket" "standard" {
  name          = "${var.project_id}-standard-${random_id.suffix.hex}"
  location      = var.bucket_location
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = var.enable_versioning
  }

  lifecycle_rule {
    condition {
      age = var.lifecycle_age_days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age                = var.lifecycle_age_days * 3
      with_state         = "ARCHIVED"
      num_newer_versions = 3
    }
    action {
      type = "Delete"
    }
  }

  labels = merge(
    var.labels,
    {
      environment = var.environment
      type        = "standard"
    }
  )

  force_destroy = true

  depends_on = [google_project_service.required_apis]
}

# Encrypted bucket with CMEK
resource "google_storage_bucket" "encrypted" {
  count         = var.enable_kms ? 1 : 0
  name          = "${var.project_id}-encrypted-${random_id.suffix.hex}"
  location      = var.bucket_location
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  encryption {
    default_kms_key_name = google_kms_crypto_key.key[0].id
  }

  versioning {
    enabled = var.enable_versioning
  }

  labels = merge(
    var.labels,
    {
      environment = var.environment
      type        = "encrypted"
    }
  )

  force_destroy = true

  depends_on = [
    google_project_service.required_apis,
    google_kms_crypto_key_iam_member.crypto_key
  ]
}

# Grant service account access to standard bucket
resource "google_storage_bucket_iam_member" "bucket_admin" {
  bucket = google_storage_bucket.standard.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.app_sa.email}"
}

# Upload sample objects
resource "google_storage_bucket_object" "sample_files" {
  for_each = {
    "config.json" = jsonencode({
      app_name    = "gcp-203-demo"
      environment = var.environment
      version     = "1.0.0"
    })
    "README.md" = <<-EOT
      # GCP-203 Training Bucket
      
      This bucket demonstrates Cloud Storage features:
      - Uniform bucket-level access
      - Public access prevention
      - Versioning
      - Lifecycle management
      - IAM integration
    EOT
  }

  name    = each.key
  bucket  = google_storage_bucket.standard.name
  content = each.value

  content_type = endswith(each.key, ".json") ? "application/json" : "text/plain"
}

# ============================================================================
# Persistent Disks
# ============================================================================

# Standard persistent disk
resource "google_compute_disk" "standard" {
  name = "gcp-203-disk-standard-${random_id.suffix.hex}"
  type = "pd-standard"
  zone = var.zone
  size = var.disk_size_gb

  labels = merge(
    var.labels,
    {
      environment = var.environment
      disk_type   = "standard"
    }
  )

  depends_on = [google_project_service.required_apis]
}

# SSD persistent disk
resource "google_compute_disk" "ssd" {
  name = "gcp-203-disk-ssd-${random_id.suffix.hex}"
  type = var.disk_type
  zone = var.zone
  size = var.disk_size_gb

  labels = merge(
    var.labels,
    {
      environment = var.environment
      disk_type   = "ssd"
    }
  )

  depends_on = [google_project_service.required_apis]
}

# Encrypted disk with CMEK
resource "google_compute_disk" "encrypted" {
  count = var.enable_kms ? 1 : 0
  name  = "gcp-203-disk-encrypted-${random_id.suffix.hex}"
  type  = var.disk_type
  zone  = var.zone
  size  = var.disk_size_gb

  disk_encryption_key {
    kms_key_self_link = google_kms_crypto_key.key[0].id
  }

  labels = merge(
    var.labels,
    {
      environment = var.environment
      disk_type   = "encrypted"
    }
  )

  depends_on = [
    google_project_service.required_apis,
    google_kms_crypto_key_iam_member.crypto_key
  ]
}

# Disk snapshot
resource "google_compute_snapshot" "backup" {
  name        = "gcp-203-snapshot-${random_id.suffix.hex}"
  source_disk = google_compute_disk.ssd.name
  zone        = var.zone

  labels = merge(
    var.labels,
    {
      environment = var.environment
      backup_type = "manual"
    }
  )

  depends_on = [google_compute_disk.ssd]
}

# ============================================================================
# Secret Manager
# ============================================================================

# Secret
resource "google_secret_manager_secret" "app_secret" {
  secret_id = "gcp-203-app-secret-${random_id.suffix.hex}"

  replication {
    auto {}
  }

  labels = var.labels

  depends_on = [google_project_service.required_apis]
}

# Secret version
resource "google_secret_manager_secret_version" "app_secret_v1" {
  secret = google_secret_manager_secret.app_secret.id

  secret_data = jsonencode({
    api_key     = "demo-api-key-${random_id.suffix.hex}"
    db_password = "demo-password-${random_id.suffix.hex}"
    environment = var.environment
  })
}

# Grant service account access to secret
resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  secret_id = google_secret_manager_secret.app_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app_sa.email}"
}