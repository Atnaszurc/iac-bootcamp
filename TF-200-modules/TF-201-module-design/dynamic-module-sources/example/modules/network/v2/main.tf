# network module v2: separate subnets per tier. Same inputs and outputs as
# v1, so switching versions doesn't break the caller.

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
  value = "v2"
}

output "subnets" {
  value = {
    web = cidrsubnet(var.cidr, 8, 10)
    app = cidrsubnet(var.cidr, 8, 20)
    db  = cidrsubnet(var.cidr, 8, 30)
  }
}
