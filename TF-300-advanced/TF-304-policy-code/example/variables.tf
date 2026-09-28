variable "environment" {
  description = "dev, staging or prod"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Team that owns these VMs"
  type        = string
  default     = "platform"
}

variable "network_name" {
  type    = string
  default = "net-dev-app"
}

variable "network_mode" {
  description = "libvirt forward mode: nat, route, open, bridge, ..."
  type        = string
  default     = "nat"
}

variable "pool" {
  description = "An existing storage pool"
  type        = string
  default     = "default"
}

variable "vms" {
  description = "VMs to create, by short name. The full name is <environment>-<short name>."
  type = map(object({
    memory      = number
    memory_unit = optional(string, "MiB")
    vcpu        = number
    disk_gib    = number
    network     = optional(string) # default: the app network
  }))
  default = {
    web = { memory = 1024, vcpu = 1, disk_gib = 10 }
  }
}
