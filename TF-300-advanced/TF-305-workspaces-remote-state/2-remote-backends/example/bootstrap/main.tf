# TF-305 Section 2: bootstrap the state bucket
#
# A remote backend needs somewhere to store state before any configuration
# can use it. This small configuration creates that bucket (with versioning,
# so every state change is kept) in Moto, a local AWS mock.
#
#   docker run -d --name moto -p 5000:5000 motoserver/moto:latest
#   terraform init && terraform apply
#
# The bootstrap itself keeps its state locally: the bucket can't store the
# state of the configuration that creates it.

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

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3 = "http://localhost:5000"
  }
}

resource "aws_s3_bucket" "state" {
  bucket = "tfstate"
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

output "bucket" {
  value = aws_s3_bucket.state.bucket
}
