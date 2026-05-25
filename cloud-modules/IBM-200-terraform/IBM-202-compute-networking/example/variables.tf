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

variable "image_name" {
  description = "Name of the IBM Cloud image to use for VSI instances."
  type        = string
  default     = "ibm-ubuntu-22-04-3-minimal-amd64-1"

  validation {
    condition     = can(regex("^ibm-", var.image_name))
    error_message = "image_name must be a valid IBM Cloud image name starting with 'ibm-'."
  }
}

variable "instance_profile" {
  description = "Instance profile for VSI instances (e.g., bx2-2x8 = 2 vCPU, 8 GB RAM)."
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
    ], var.instance_profile)
    error_message = "instance_profile must be a valid IBM Cloud instance profile."
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

variable "create_instances" {
  description = "Whether to create VSI instances. Set to false to only create VPC and networking."
  type        = bool
  default     = false
}

variable "multi_zone" {
  description = "Whether to create resources in multiple availability zones for high availability."
  type        = bool
  default     = false
}

variable "assign_floating_ip" {
  description = "Whether to assign a floating IP to the zone 1 instance for direct public access."
  type        = bool
  default     = false
}

variable "user_data" {
  description = "User data script to run on instance initialization (cloud-init)."
  type        = string
  default     = ""

  validation {
    condition     = var.user_data == "" || can(regex("^#!", var.user_data))
    error_message = "user_data must be empty or start with a shebang (#!)."
  }
}
