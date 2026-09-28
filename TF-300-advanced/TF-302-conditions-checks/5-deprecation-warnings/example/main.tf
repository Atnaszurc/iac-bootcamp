# TF-302 Section 5: Deprecation warnings
#
# This configuration WORKS, but uses two things its providers have deprecated:
#   - random_string's `number` argument (use `numeric`)
#   - the whole null_data_source data source (use locals or terraform_data)
#
#   terraform init
#   terraform apply        # read the warnings
#
# Your task: migrate it so `terraform plan` shows no warnings and no changes.
# The answer is in solution/.

terraform {
  required_version = ">= 1.15.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# A suffix for VM names: letters only
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  number  = false # deprecated
}

# An old way to build intermediate values
data "null_data_source" "names" { # deprecated
  inputs = {
    web = "web-${random_string.suffix.result}"
    db  = "db-${random_string.suffix.result}"
  }
}

output "vm_names" {
  value = data.null_data_source.names.outputs
}
