variable "project_name" {
  description = "Project name used to prefix all resources"
  type        = string
  default     = "tf-103"
}

variable "base_image_url" {
  description = "URL or local path to the base cloud image (qcow2 format)"
  type        = string
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... terraform-training"
}