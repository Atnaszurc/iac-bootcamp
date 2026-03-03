variable "vm_pools" {
  description = <<-EOT
    Map of VM deployment pools. Each key is a pool name (e.g. "stable", "canary").
    Add a new entry to spin up a canary pool alongside the stable pool.
    Remove the old entry to complete the blue-green cutover.
  EOT
  type = map(object({
    base_image_url = string
    memory_mb      = number
    vcpu_count     = number
    vm_count       = number
  }))
  default = {
    stable = {
      base_image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
      memory_mb      = 1024
      vcpu_count     = 1
      vm_count       = 2
    }
  }
}

variable "ssh_public_key" {
  description = "SSH public key to inject into VMs via cloud-init"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... replace-with-your-key"
}
