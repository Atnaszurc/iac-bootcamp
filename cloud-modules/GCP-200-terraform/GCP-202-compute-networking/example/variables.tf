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

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "custom-vpc"
}

variable "public_subnet_cidr" {
  description = "CIDR range for public subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Must be a valid CIDR range."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR range for private subnet"
  type        = string
  default     = "10.0.2.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "Must be a valid CIDR range."
  }
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "machine_type" {
  description = "Machine type for compute instances"
  type        = string
  default     = "e2-medium"

  validation {
    condition = contains([
      "e2-micro", "e2-small", "e2-medium",
      "n2-standard-2", "n2-standard-4"
    ], var.machine_type)
    error_message = "Machine type must be a valid GCP machine type."
  }
}

variable "enable_nat" {
  description = "Enable Cloud NAT for private subnet"
  type        = bool
  default     = true
}

variable "ssh_user" {
  description = "SSH username for instances"
  type        = string
  default     = "terraform"
}

variable "ssh_public_key_file" {
  description = "Path to SSH public key file (ignored if ssh_public_key is set)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_public_key" {
  description = "SSH public key content (takes precedence over ssh_public_key_file)"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    course     = "gcp-202"
  }
}