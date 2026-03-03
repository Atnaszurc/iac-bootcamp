# TF-305 Section 3: Remote State Sharing — Producer Configuration
# This is the "networking" layer that other configurations consume.

terraform {
  required_version = ">= 1.14"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }

  # Store state in a shared location so other configs can read it
  backend "local" {
    path = "../../shared-state/networking.tfstate"
  }
}

# Simulate a network resource using local_file (no Libvirt required for this demo)
resource "local_file" "network_config" {
  content = <<-EOT
    # Simulated Network Configuration
    # In a real setup, this would be a libvirt_network resource
    network_id   = ${var.network_id}
    network_name = ${var.network_name}
    network_cidr = ${var.network_cidr}
  EOT
  filename = "${path.module}/network.conf"
}