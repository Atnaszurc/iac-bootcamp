variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "app-server"
}

variable "vm_memory_mb" {
  description = "Memory allocation in MB"
  type        = number
  default     = 1024
}

variable "vm_cpus" {
  description = "Number of virtual CPUs"
  type        = number
  default     = 2
}