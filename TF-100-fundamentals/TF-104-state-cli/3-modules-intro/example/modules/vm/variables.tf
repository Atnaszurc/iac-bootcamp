variable "vm_name" {
  description = "Name for the VM and all associated resources"
  type        = string
}

variable "base_image_url" {
  description = "URL or local path to the base cloud image (qcow2)"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key to inject via cloud-init"
  type        = string
}

variable "memory_mb" {
  description = "RAM allocated to the VM in megabytes"
  type        = number
  default     = 1024
}

variable "vcpu_count" {
  description = "Number of virtual CPUs"
  type        = number
  default     = 1
}

variable "disk_size_bytes" {
  description = "Disk size in bytes"
  type        = number
  default     = 10737418240 # 10 GB
}

variable "network_cidr" {
  description = "CIDR block for the VM's NAT network"
  type        = string
  default     = "10.50.0.0/24"
}