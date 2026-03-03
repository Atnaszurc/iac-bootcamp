variable "project_name" {
  description = "Project name used to prefix all resources"
  type        = string
  default     = "tf-103"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "base_image_url" {
  description = "URL or local path to the base cloud image (qcow2 format)"
  type        = string
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

variable "disk_size_bytes" {
  description = "VM disk size in bytes (default: 10 GB)"
  type        = number
  default     = 10737418240  # 10 GB
}

variable "memory_mb" {
  description = "VM memory in megabytes"
  type        = number
  default     = 1024
}

variable "vcpu_count" {
  description = "Number of virtual CPUs"
  type        = number
  default     = 1
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... terraform-training"
}
