# TF-307 Part 1: List resources & terraform query
#
# The standard .tf configuration declares providers. Query files
# (*.tfquery.hcl) cannot contain a terraform block — they reuse this one.
#
# The AWS provider points at Moto (an open-source AWS API mock running in
# Docker), so this works without an AWS account. See the README for why.
#
#   docker run -d --name moto -p 5000:5000 motoserver/moto:latest
#   (cd seed && terraform init && terraform apply && rm terraform.tfstate*)
#   terraform init
#   terraform query

terraform {
  required_version = ">= 1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  # Moto accepts any credentials; these are not real keys
  access_key = "test"
  secret_key = "test"

  # Don't talk to real AWS for account and metadata lookups
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2 = var.moto_endpoint
    s3  = var.moto_endpoint
    sts = var.moto_endpoint
  }
}

variable "moto_endpoint" {
  description = "Where the Moto server listens"
  type        = string
  default     = "http://localhost:5000"
}
