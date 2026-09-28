variable "vm_name" {
  type    = string
  default = "tf302-web"
}

variable "memory_mb" {
  type    = number
  default = 1024
}

variable "network_cidr" {
  type    = string
  default = "10.160.0.0/24"
}

variable "min_host_headroom_mb" {
  description = "Memory that should stay free on the host after this VM"
  type        = number
  default     = 4096
}

variable "base_image_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}
