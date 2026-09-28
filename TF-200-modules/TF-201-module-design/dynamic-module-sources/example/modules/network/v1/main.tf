# network module v1: one flat subnet for everything

variable "name" {
  type = string
}

variable "cidr" {
  type = string
}

output "name" {
  value = var.name
}

output "module_version" {
  value = "v1"
}

output "subnets" {
  value = {
    all = cidrsubnet(var.cidr, 8, 0)
  }
}
