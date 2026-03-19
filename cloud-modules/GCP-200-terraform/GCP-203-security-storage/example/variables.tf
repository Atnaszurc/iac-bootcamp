variable "project_id" {
  description = "The GCP project ID"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "service_account_name" {
  description = "Name for the service account"
  type        = string
  default     = "app-service-account"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.service_account_name))
    error_message = "Service account name must be 6-30 characters, lowercase letters, numbers, and hyphens."
  }
}

variable "bucket_location" {
  description = "Location for Cloud Storage buckets"
  type        = string
  default     = "US"

  validation {
    condition = contains([
      "US", "EU", "ASIA",
      "us-central1", "us-east1", "europe-west1"
    ], var.bucket_location)
    error_message = "Bucket location must be a valid GCP location."
  }
}

variable "enable_kms" {
  description = "Enable Cloud KMS encryption"
  type        = bool
  default     = true
}

variable "kms_key_rotation_period" {
  description = "KMS key rotation period in seconds (90 days default)"
  type        = string
  default     = "7776000s"
}

variable "disk_size_gb" {
  description = "Size of persistent disk in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.disk_size_gb >= 10 && var.disk_size_gb <= 1000
    error_message = "Disk size must be between 10 and 1000 GB."
  }
}

variable "disk_type" {
  description = "Type of persistent disk"
  type        = string
  default     = "pd-ssd"

  validation {
    condition     = contains(["pd-standard", "pd-balanced", "pd-ssd"], var.disk_type)
    error_message = "Disk type must be pd-standard, pd-balanced, or pd-ssd."
  }
}

variable "enable_versioning" {
  description = "Enable versioning for Cloud Storage buckets"
  type        = bool
  default     = true
}

variable "lifecycle_age_days" {
  description = "Age in days for lifecycle management"
  type        = number
  default     = 30

  validation {
    condition     = var.lifecycle_age_days >= 1 && var.lifecycle_age_days <= 365
    error_message = "Lifecycle age must be between 1 and 365 days."
  }
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    course     = "gcp-203"
  }
}