# Component: naming
#
# A unique, readable prefix per deployment, like "dev-tender-owl".
# random_pet is a real managed resource: it counts toward RUM.

terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

variable "environment" {
  type = string
}

resource "random_pet" "this" {
  length = 2

  # A new environment gets a new name
  keepers = {
    environment = var.environment
  }
}

output "prefix" {
  value = "${var.environment}-${random_pet.this.id}"
}
