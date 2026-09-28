# TF-201: Dynamic module sources (Terraform 1.15+)
#
# The network module comes in two versions, and each environment pins its
# own: dev tries v2 first, prod stays on v1 until v2 has proven itself.
#
#   terraform init                          # dev: installs modules/network/v2
#   terraform plan
#   terraform init -var environment=prod    # prod: installs modules/network/v1
#   terraform plan -var environment=prod    # the same value as at init

terraform {
  required_version = ">= 1.15.0"
}

locals {
  # A local may be used in source too, as long as it only depends on
  # const variables and literals
  network_module_version = {
    dev  = "v2"
    prod = "v1"
  }[var.environment]
}

module "network" {
  source = "./modules/network/${local.network_module_version}"

  name = "lab-${var.environment}"
  cidr = var.network_cidr
}

# A registry module whose version comes from a const variable
module "motd" {
  source  = "hashicorp/dir/template"
  version = var.template_module_version

  base_dir = "${path.module}/templates"
  template_vars = {
    environment    = var.environment
    network_name   = module.network.name
    module_version = module.network.module_version
  }
}
