variable "vm_name" {
  type    = string
  default = "tf302-conditions"
}

variable "memory_mb" {
  type    = number
  default = 1024
}

variable "disk_gib" {
  type    = number
  default = 10
}

variable "network_cidr" {
  type    = string
  default = "10.150.0.0/24"
}

variable "reserved_cidrs" {
  description = "Ranges already in use on this host (libvirt's default network, your LAN, a VPN...)"
  type        = list(string)
  default     = ["192.168.122.0/24"]
}

variable "min_free_gib" {
  description = "Free space the storage pool must have after creation"
  type        = number
  default     = 5
}

variable "base_image_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}
