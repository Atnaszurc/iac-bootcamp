variable "ibm_region" {
  description = "IBM Cloud region to use for this lesson."
  type        = string
  default     = "us-south"

  validation {
    condition = contains([
      "au-syd",
      "br-sao",
      "ca-tor",
      "eu-de",
      "eu-es",
      "eu-gb",
      "jp-osa",
      "jp-tok",
      "us-east",
      "us-south",
    ], var.ibm_region)
    error_message = "ibm_region must be a supported IBM Cloud region used by this course."
  }
}

variable "resource_group_name" {
  description = "IBM Cloud resource group name to resolve for the lesson example."
  type        = string
  default     = "Default"
}

variable "environment" {
  description = "Environment label used for naming and tagging examples."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "stage", "prod"], lower(var.environment))
    error_message = "environment must be one of: dev, test, stage, prod."
  }
}

variable "project_name" {
  description = "Project name used in resource naming convention."
  type        = string
  default     = "training"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

# =====================================================================================
# Security Group Variables
# =====================================================================================

variable "allow_ssh_from_internet" {
  description = "Whether to allow SSH access from the internet to web tier."
  type        = bool
  default     = false
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed for SSH access (if allow_ssh_from_internet is true)."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "ssh_allowed_cidr must be a valid CIDR block."
  }
}

variable "allow_ping" {
  description = "Whether to allow ICMP ping to web tier."
  type        = bool
  default     = true
}

variable "enable_mysql_port" {
  description = "Whether to enable MySQL port (3306) in database tier security group."
  type        = bool
  default     = false
}

# =====================================================================================
# Key Protect Variables
# =====================================================================================

variable "create_key_protect" {
  description = "Whether to create IBM Key Protect instance and root key."
  type        = bool
  default     = false
}

variable "key_protect_plan" {
  description = "IBM Key Protect service plan."
  type        = string
  default     = "tiered-pricing"

  validation {
    condition     = contains(["tiered-pricing"], var.key_protect_plan)
    error_message = "key_protect_plan must be 'tiered-pricing'."
  }
}

# =====================================================================================
# Cloud Object Storage Variables
# =====================================================================================

variable "create_cos" {
  description = "Whether to create IBM Cloud Object Storage instance and buckets."
  type        = bool
  default     = false
}

variable "cos_plan" {
  description = "IBM Cloud Object Storage service plan."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "lite"], var.cos_plan)
    error_message = "cos_plan must be 'standard' or 'lite'."
  }
}

variable "cos_storage_class" {
  description = "Storage class for COS buckets."
  type        = string
  default     = "standard"

  validation {
    condition = contains([
      "standard",
      "vault",
      "cold",
      "flex",
      "smart"
    ], var.cos_storage_class)
    error_message = "cos_storage_class must be one of: standard, vault, cold, flex, smart."
  }
}

variable "enable_cos_encryption" {
  description = "Whether to enable Key Protect encryption for COS buckets. Requires create_key_protect=true."
  type        = bool
  default     = false
}

variable "enable_activity_tracking" {
  description = "Whether to enable activity tracking for COS buckets."
  type        = bool
  default     = true
}

variable "enable_metrics_monitoring" {
  description = "Whether to enable metrics monitoring for COS buckets."
  type        = bool
  default     = true
}

variable "bucket_hard_quota_gb" {
  description = "Hard quota for COS bucket in GB (0 = no quota)."
  type        = number
  default     = 0

  validation {
    condition     = var.bucket_hard_quota_gb >= 0
    error_message = "bucket_hard_quota_gb must be 0 or greater."
  }
}

# =====================================================================================
# Lifecycle Policy Variables
# =====================================================================================

variable "enable_lifecycle_policies" {
  description = "Whether to create a bucket with lifecycle policies."
  type        = bool
  default     = false
}

variable "archive_days" {
  description = "Number of days before archiving objects to cold storage."
  type        = number
  default     = 90

  validation {
    condition     = var.archive_days > 0 && var.archive_days <= 3650
    error_message = "archive_days must be between 1 and 3650."
  }
}

variable "expire_days" {
  description = "Number of days before expiring (deleting) objects."
  type        = number
  default     = 365

  validation {
    condition     = var.expire_days > 0 && var.expire_days <= 3650
    error_message = "expire_days must be between 1 and 3650."
  }
}
