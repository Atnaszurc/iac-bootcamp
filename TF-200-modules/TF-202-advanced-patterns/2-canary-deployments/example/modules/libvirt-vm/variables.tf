# =============================================================================
# modules/libvirt-vm/variables.tf
# =============================================================================

variable "pool_name" {
  description = "Name of this deployment pool (e.g. 'stable', 'canary'). Used as a prefix for all resource names."
  type        = string
}

variable "base_image_url" {
  description = "URL or local path to the base cloud image (qcow2 format)."
  type        = string
}

variable "memory_mb" {
  description = "RAM allocated to each VM in this pool (MiB)."
  type        = number
  default     = 512
}

variable "vcpu_count" {
  description = "Number of vCPUs for each VM in this pool."
  type        = number
  default     = 1
}

variable "vm_count" {
  description = "Number of VMs to create in this pool."
  type        = number
  default     = 1
}

variable "disk_size_bytes" {
  description = "Disk size for each VM volume in bytes (default 5 GiB)."
  type        = number
  default     = 5368709120 # 5 GiB
}

variable "ssh_public_key" {
  description = "SSH public key injected into VMs via cloud-init."
  type        = string
}

variable "storage_pool" {
  description = "Name of the libvirt storage pool to use for volumes."
  type        = string
}

variable "network_id" {
  description = "Name of the libvirt network to attach VMs to (in 0.9.3, use network name not ID)."
  type        = string
}