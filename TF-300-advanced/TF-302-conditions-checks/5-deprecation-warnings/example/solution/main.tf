# TF-302 Section 5: Deprecation warnings — migrated
#
# Copy this over ../main.tf in an already-applied working directory and run
# `terraform plan`: no warnings, and no changes. The suffix (and so every
# VM name) stays the same.

terraform {
  required_version = ">= 1.15.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = false # was: number
}

# was: data "null_data_source" — plain locals do the same job
locals {
  vm_names = {
    web = "web-${random_string.suffix.result}"
    db  = "db-${random_string.suffix.result}"
  }
}

output "vm_names" {
  value = local.vm_names
}
