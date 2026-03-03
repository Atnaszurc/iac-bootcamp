variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "tf104-state"
}

variable "base_image_url" {
  description = "URL or local path to the base cloud image (qcow2)"
  type        = string
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

variable "ssh_public_key" {
  description = "SSH public key to inject into the VM via cloud-init"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... replace-with-your-key"
}

variable "memory_mb" {
  description = "RAM allocated to the VM in megabytes"
  type        = number
  default     = 1024
}

variable "vcpu_count" {
  description = "Number of virtual CPUs for the VM"
  type        = number
  default     = 1
}
