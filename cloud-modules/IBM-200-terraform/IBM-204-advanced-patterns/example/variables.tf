# =====================================================================================
# Core Configuration Variables
# =====================================================================================

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
# Deployment Control Variables
# =====================================================================================

variable "deploy_compute" {
  description = "Whether to deploy compute instances (web, app, database tiers)."
  type        = bool
  default     = false
}

variable "deploy_load_balancer" {
  description = "Whether to deploy the application load balancer."
  type        = bool
  default     = false
}

variable "deploy_key_protect" {
  description = "Whether to deploy IBM Key Protect for encryption."
  type        = bool
  default     = false
}

variable "deploy_cos" {
  description = "Whether to deploy IBM Cloud Object Storage."
  type        = bool
  default     = false
}

variable "multi_zone" {
  description = "Whether to deploy resources across multiple availability zones for high availability."
  type        = bool
  default     = false
}

# =====================================================================================
# Compute Configuration Variables
# =====================================================================================

variable "image_name" {
  description = "Name of the IBM Cloud image to use for VSI instances."
  type        = string
  default     = "ibm-ubuntu-22-04-3-minimal-amd64-1"

  validation {
    condition     = can(regex("^ibm-", var.image_name))
    error_message = "image_name must be a valid IBM Cloud image name starting with 'ibm-'."
  }
}

variable "ssh_public_key" {
  description = "SSH public key content for VSI access. Leave empty to skip SSH key creation."
  type        = string
  default     = ""
  sensitive   = false

  validation {
    condition     = var.ssh_public_key == "" || can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)", var.ssh_public_key))
    error_message = "ssh_public_key must be empty or a valid SSH public key."
  }
}

# Web Tier Configuration
variable "web_tier_instance_count" {
  description = "Number of web tier instances per zone."
  type        = number
  default     = 1

  validation {
    condition     = var.web_tier_instance_count >= 1 && var.web_tier_instance_count <= 10
    error_message = "web_tier_instance_count must be between 1 and 10."
  }
}

variable "web_tier_instance_profile" {
  description = "Instance profile for web tier instances."
  type        = string
  default     = "bx2-2x8"

  validation {
    condition = contains([
      "bx2-2x8",
      "bx2-4x16",
      "bx2-8x32",
      "cx2-2x4",
      "cx2-4x8",
    ], var.web_tier_instance_profile)
    error_message = "web_tier_instance_profile must be a valid IBM Cloud instance profile."
  }
}

variable "web_tier_user_data" {
  description = "User data script for web tier instances (cloud-init)."
  type        = string
  default     = ""
}

# Application Tier Configuration
variable "app_tier_instance_count" {
  description = "Number of application tier instances per zone."
  type        = number
  default     = 1

  validation {
    condition     = var.app_tier_instance_count >= 1 && var.app_tier_instance_count <= 10
    error_message = "app_tier_instance_count must be between 1 and 10."
  }
}

variable "app_tier_instance_profile" {
  description = "Instance profile for application tier instances."
  type        = string
  default     = "bx2-2x8"

  validation {
    condition = contains([
      "bx2-2x8",
      "bx2-4x16",
      "bx2-8x32",
      "cx2-2x4",
      "cx2-4x8",
      "mx2-2x16",
      "mx2-4x32",
    ], var.app_tier_instance_profile)
    error_message = "app_tier_instance_profile must be a valid IBM Cloud instance profile."
  }
}

variable "app_tier_user_data" {
  description = "User data script for application tier instances (cloud-init)."
  type        = string
  default     = ""
}

# Database Tier Configuration
variable "database_tier_instance_profile" {
  description = "Instance profile for database tier instances."
  type        = string
  default     = "bx2-4x16"

  validation {
    condition = contains([
      "bx2-2x8",
      "bx2-4x16",
      "bx2-8x32",
      "mx2-2x16",
      "mx2-4x32",
      "mx2-8x64",
    ], var.database_tier_instance_profile)
    error_message = "database_tier_instance_profile must be a valid IBM Cloud instance profile."
  }
}

variable "database_tier_user_data" {
  description = "User data script for database tier instances (cloud-init)."
  type        = string
  default     = ""
}

# =====================================================================================
# Security Configuration Variables
# =====================================================================================

variable "enable_ssh_access" {
  description = "Whether to enable SSH access to instances."
  type        = bool
  default     = false
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed for SSH access (if enable_ssh_access is true)."
  type        = string
  default     = "10.0.0.0/8"

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "ssh_allowed_cidr must be a valid CIDR block."
  }
}

# =====================================================================================
# Load Balancer Configuration Variables
# =====================================================================================

variable "lb_algorithm" {
  description = "Load balancing algorithm for distributing traffic."
  type        = string
  default     = "round_robin"

  validation {
    condition     = contains(["round_robin", "weighted_round_robin", "least_connections"], var.lb_algorithm)
    error_message = "lb_algorithm must be one of: round_robin, weighted_round_robin, least_connections."
  }
}

variable "lb_health_delay" {
  description = "Seconds between health checks."
  type        = number
  default     = 5

  validation {
    condition     = var.lb_health_delay >= 2 && var.lb_health_delay <= 60
    error_message = "lb_health_delay must be between 2 and 60 seconds."
  }
}

variable "lb_health_retries" {
  description = "Number of health check retries before marking instance unhealthy."
  type        = number
  default     = 2

  validation {
    condition     = var.lb_health_retries >= 1 && var.lb_health_retries <= 10
    error_message = "lb_health_retries must be between 1 and 10."
  }
}

variable "lb_health_timeout" {
  description = "Seconds to wait for health check response."
  type        = number
  default     = 2

  validation {
    condition     = var.lb_health_timeout >= 1 && var.lb_health_timeout <= 59
    error_message = "lb_health_timeout must be between 1 and 59 seconds."
  }
}

variable "lb_health_monitor_url" {
  description = "URL path for health check endpoint."
  type        = string
  default     = "/health"

  validation {
    condition     = can(regex("^/", var.lb_health_monitor_url))
    error_message = "lb_health_monitor_url must start with /."
  }
}
