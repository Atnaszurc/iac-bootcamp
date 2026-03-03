variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "tf103-vms"
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

variable "vms" {
  description = "Map of VMs to create. Key = VM name suffix."
  type = map(object({
    memory_mb       = number
    vcpu_count      = number
    disk_size_bytes = number
  }))
  default = {
    web = {
      memory_mb       = 1024
      vcpu_count      = 1
      disk_size_bytes = 10737418240 # 10 GB
    }
    db = {
      memory_mb       = 2048
      vcpu_count      = 2
      disk_size_bytes = 21474836480 # 20 GB
    }
  }
}
