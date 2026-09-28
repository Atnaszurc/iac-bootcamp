# =============================================================================
# modules/libvirt-vm/variables.tf
# =============================================================================

variable "pool_name" {
  description = "Name of this deployment pool (e.g. 'blue', 'green'). Used as a prefix for all resource names."
  type        = string
}

variable "base_image_url" {
  description = "URL or local path to the base cloud image (qcow2 format). Changing it rolls the pool to a new generation."
  type        = string
}

variable "memory_mb" {
  description = "RAM allocated to each VM in this pool (MiB). Changing it rolls the pool to a new generation."
  type        = number
  default     = 1024
}

variable "vcpu_count" {
  description = "Number of vCPUs for each VM in this pool. Changing it rolls the pool to a new generation."
  type        = number
  default     = 1
}

variable "vm_count" {
  description = "Number of VMs to create in this pool."
  type        = number
  default     = 1
}

variable "disk_size_bytes" {
  description = "Disk size for each VM volume in bytes (default 10 GiB)."
  type        = number
  default     = 10737418240 # 10 GiB
}

variable "ssh_public_key" {
  description = "SSH public key injected into VMs via cloud-init."
  type        = string
}

variable "storage_pool" {
  description = "Name of the libvirt storage pool to use for volumes."
  type        = string
}

variable "network_name" {
  description = "Name of the libvirt network to attach VMs to. Interfaces reference networks by name, not ID."
  type        = string
}
