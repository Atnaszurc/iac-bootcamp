variable "subscription_id" {
  description = "Azure subscription ID. Can also be set via ARM_SUBSCRIPTION_ID env var."
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region to deploy resources in"
  type        = string
  default     = "West Europe"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "az202"
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B1s"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  # Valid test RSA key - DO NOT use in production
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDY5O6Vlecaw4jVcv15DNFm5VJYtWcjKPpentQHWNcuFCUl/7TAR+3B418mWGZhgDbExH+ipVyq+Bz9hS5wugYjSsaiMPa5X2wjKSCMOwUWnluzUgSFnHhyj45NWFI0S7atbU9sqGE5tqXEh1tMqkIkp1tWJexKMd4Q8M4nCJVMOtcG2CWuh7BUdJLPcMzOaYGgSNxaOvabpT8+cMoVINrIVd1UTwKi7h5WthKID72drCt2lHG1pzQnPK6DkzjTbGlul/19Lm1d8DjMAg7GMXAEaa7dbWIt4LrZCNCv/0oZ0XQlxWxl1INgKEuOIsLjf4geafwqiEGtZdcZFFjPIplt terraform-test@example.com"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the VM (use your IP: x.x.x.x/32)"
  type        = string
  default     = "*" # Restrict this in production!
}