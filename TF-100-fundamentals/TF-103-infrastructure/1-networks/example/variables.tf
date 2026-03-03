variable "network_name" {
  description = "Base name for the libvirt networks"
  type        = string
  default     = "tf-103"
}

variable "network_cidr" {
  description = "CIDR block for the NAT network"
  type        = string
  default     = "10.10.0.0/24"

  validation {
    condition     = can(cidrnetmask(var.network_cidr))
    error_message = "network_cidr must be a valid CIDR block (e.g. 10.10.0.0/24)."
  }
}
