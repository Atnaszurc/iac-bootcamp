# Component: app
#
# Stands in for your application. terraform_data doesn't count toward
# resources under management, so this component is free to run.
# To build the Stack out, replace it with real resources (see the README).

variable "name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "owner" {
  type = string
}

variable "replicas" {
  type = number

  validation {
    condition     = var.replicas >= 1 && var.replicas <= 3
    error_message = "replicas must be between 1 and 3."
  }
}

locals {
  instance_names = [for i in range(var.replicas) : "${var.name_prefix}-app-${i}"]
}

resource "terraform_data" "config" {
  input = {
    environment = var.environment
    owner       = var.owner
    instances   = local.instance_names
  }
}

output "instance_names" {
  value = terraform_data.config.output.instances
}
