variable "network_id" {
  description = "Simulated network ID"
  type        = string
  default     = "net-001"
}

variable "network_name" {
  description = "Name of the network"
  type        = string
  default     = "main-network"
}

variable "network_cidr" {
  description = "CIDR block for the network"
  type        = string
  default     = "10.0.0.0/24"
}