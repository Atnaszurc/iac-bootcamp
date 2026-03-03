variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "tf104-modules"
}

variable "base_image_url" {
  description = "URL or local path to the base cloud image (qcow2)"
  type        = string
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

variable "ssh_public_key" {
  description = "SSH public key to inject into VMs via cloud-init"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... replace-with-your-key"
}
