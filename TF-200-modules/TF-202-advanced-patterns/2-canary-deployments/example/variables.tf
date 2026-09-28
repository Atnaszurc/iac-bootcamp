variable "vm_pools" {
  description = <<-EOT
    Map of VM deployment pools. Each key is a pool name (e.g. "blue", "green").
    Add an entry to deploy a new pool next to the existing one, adjust weight
    to shift traffic, and remove the old entry to complete the cutover.
    weight is per VM (HAProxy server weight, 0-256). 0 = receives no traffic.
  EOT
  type = map(object({
    base_image_url = string
    memory_mb      = optional(number, 1024)
    vcpu_count     = optional(number, 1)
    vm_count       = optional(number, 1)
    weight         = optional(number, 100)
  }))
  default = {
    blue = {
      base_image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
      vm_count       = 2
    }
  }

  validation {
    condition     = alltrue([for p in values(var.vm_pools) : p.weight >= 0 && p.weight <= 256])
    error_message = "weight must be between 0 and 256 (HAProxy server weight)."
  }

  validation {
    condition     = length(var.vm_pools) == 0 || anytrue([for p in values(var.vm_pools) : p.weight > 0])
    error_message = "At least one pool needs a weight above 0, or no VM will receive traffic."
  }
}

variable "project_name" {
  description = "Prefix for the shared network and storage pool"
  type        = string
  default     = "canary"
}

variable "network_cidr" {
  description = "CIDR block for the shared NAT network"
  type        = string
  default     = "10.210.0.0/24"
}

variable "lb_port" {
  description = "Port HAProxy listens on"
  type        = number
  default     = 8080
}

variable "ssh_public_key" {
  description = "SSH public key to inject into VMs via cloud-init"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... replace-with-your-key"
}
