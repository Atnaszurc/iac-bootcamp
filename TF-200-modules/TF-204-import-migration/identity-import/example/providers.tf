terraform {
  required_version = ">= 1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# The AWS provider pointed at Moto, a local AWS API mock (see the README:
# "Why Moto?"). Remove the Moto-only settings to use a real AWS account.
provider "aws" {
  region = "us-east-1"

  # Moto accepts any credentials; these are not real keys
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    iam = var.moto_endpoint
    s3  = var.moto_endpoint
    sts = var.moto_endpoint
  }
}

variable "moto_endpoint" {
  description = "Where the Moto server listens"
  type        = string
  default     = "http://localhost:5000"
}
