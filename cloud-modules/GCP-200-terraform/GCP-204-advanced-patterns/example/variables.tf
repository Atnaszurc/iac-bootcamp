# ============================================================================
# Project Configuration
# ============================================================================

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

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Region must be a valid GCP region format (e.g., us-central1)."
  }
}

variable "zone" {
  description = "The GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]-[a-z]$", var.zone))
    error_message = "Zone must be a valid GCP zone format (e.g., us-central1-a)."
  }
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

# ============================================================================
# Network Configuration
# ============================================================================

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "gcp-204-vpc"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "Subnet CIDR must be a valid IPv4 CIDR block."
  }
}

# ============================================================================
# Managed Instance Group Configuration
# ============================================================================

variable "instance_template_machine_type" {
  description = "Machine type for instance template"
  type        = string
  default     = "e2-small"
}

variable "instance_template_disk_size" {
  description = "Boot disk size in GB for instance template"
  type        = number
  default     = 10

  validation {
    condition     = var.instance_template_disk_size >= 10 && var.instance_template_disk_size <= 1000
    error_message = "Disk size must be between 10 and 1000 GB."
  }
}

variable "instance_template_image" {
  description = "Boot disk image for instance template"
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "mig_target_size" {
  description = "Target size for the managed instance group"
  type        = number
  default     = 2

  validation {
    condition     = var.mig_target_size >= 1 && var.mig_target_size <= 10
    error_message = "MIG target size must be between 1 and 10."
  }
}

variable "autoscaler_min_replicas" {
  description = "Minimum number of instances for autoscaling"
  type        = number
  default     = 2

  validation {
    condition     = var.autoscaler_min_replicas >= 1
    error_message = "Minimum replicas must be at least 1."
  }
}

variable "autoscaler_max_replicas" {
  description = "Maximum number of instances for autoscaling"
  type        = number
  default     = 5

  validation {
    condition     = var.autoscaler_max_replicas >= var.autoscaler_min_replicas
    error_message = "Maximum replicas must be greater than or equal to minimum replicas."
  }
}

variable "autoscaler_cpu_target" {
  description = "Target CPU utilization for autoscaling (0.0 to 1.0)"
  type        = number
  default     = 0.6

  validation {
    condition     = var.autoscaler_cpu_target > 0 && var.autoscaler_cpu_target <= 1
    error_message = "CPU target must be between 0 and 1."
  }
}

variable "autoscaler_cooldown_period" {
  description = "Cooldown period in seconds for autoscaling"
  type        = number
  default     = 60

  validation {
    condition     = var.autoscaler_cooldown_period >= 30
    error_message = "Cooldown period must be at least 30 seconds."
  }
}

# ============================================================================
# Load Balancer Configuration
# ============================================================================

variable "health_check_port" {
  description = "Port for health check"
  type        = number
  default     = 80

  validation {
    condition     = var.health_check_port > 0 && var.health_check_port <= 65535
    error_message = "Health check port must be between 1 and 65535."
  }
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 10

  validation {
    condition     = var.health_check_interval >= 5
    error_message = "Health check interval must be at least 5 seconds."
  }
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5

  validation {
    condition     = var.health_check_timeout >= 1
    error_message = "Health check timeout must be at least 1 second."
  }
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks"
  type        = number
  default     = 2

  validation {
    condition     = var.health_check_healthy_threshold >= 1
    error_message = "Healthy threshold must be at least 1."
  }
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks"
  type        = number
  default     = 3

  validation {
    condition     = var.health_check_unhealthy_threshold >= 1
    error_message = "Unhealthy threshold must be at least 1."
  }
}

# ============================================================================
# Cloud SQL Configuration
# ============================================================================

variable "enable_cloud_sql" {
  description = "Enable Cloud SQL instance"
  type        = bool
  default     = true
}

variable "database_version" {
  description = "Database version (POSTGRES_15, MYSQL_8_0, etc.)"
  type        = string
  default     = "POSTGRES_15"

  validation {
    condition     = contains(["POSTGRES_15", "POSTGRES_14", "MYSQL_8_0", "MYSQL_5_7"], var.database_version)
    error_message = "Database version must be POSTGRES_15, POSTGRES_14, MYSQL_8_0, or MYSQL_5_7."
  }
}

variable "database_tier" {
  description = "Database tier (machine type)"
  type        = string
  default     = "db-f1-micro"
}

variable "database_disk_size" {
  description = "Database disk size in GB"
  type        = number
  default     = 10

  validation {
    condition     = var.database_disk_size >= 10 && var.database_disk_size <= 1000
    error_message = "Database disk size must be between 10 and 1000 GB."
  }
}

variable "database_disk_type" {
  description = "Database disk type (PD_SSD or PD_HDD)"
  type        = string
  default     = "PD_SSD"

  validation {
    condition     = contains(["PD_SSD", "PD_HDD"], var.database_disk_type)
    error_message = "Database disk type must be PD_SSD or PD_HDD."
  }
}

variable "database_backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "database_backup_start_time" {
  description = "Backup start time in HH:MM format (UTC)"
  type        = string
  default     = "03:00"

  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.database_backup_start_time))
    error_message = "Backup start time must be in HH:MM format (00:00 to 23:59)."
  }
}

variable "database_ha_enabled" {
  description = "Enable high availability (regional)"
  type        = bool
  default     = false
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.database_name))
    error_message = "Database name must start with a letter and contain only lowercase letters, numbers, and underscores (max 63 chars)."
  }
}

variable "database_user" {
  description = "Database user name"
  type        = string
  default     = "appuser"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.database_user))
    error_message = "Database user must start with a letter and contain only lowercase letters, numbers, and underscores (max 63 chars)."
  }
}

# ============================================================================
# Labels
# ============================================================================

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default = {
    course     = "gcp-204"
    managed_by = "terraform"
  }

  validation {
    condition     = alltrue([for k, v in var.labels : can(regex("^[a-z0-9_-]{1,63}$", k)) && can(regex("^[a-z0-9_-]{0,63}$", v))])
    error_message = "Label keys and values must contain only lowercase letters, numbers, underscores, and hyphens (max 63 chars)."
  }
}