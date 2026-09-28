# Query files may contain only list, provider, variable and locals blocks.
# Run: terraform query
#      terraform query -generate-config-out=generated.tf

variable "environment_tag" {
  description = "Value of the Environment tag to search for"
  type        = string
  default     = "prod"
}

# EC2 instances tagged with the requested environment.
# Provider-specific arguments go inside config {}.
list "aws_instance" "tagged" {
  provider = aws
  limit    = 50 # default is 100 results per list block

  config {
    filter {
      name   = "tag:Environment"
      values = [var.environment_tag]
    }
  }
}

# Every S3 bucket in the account
list "aws_s3_bucket" "all" {
  provider = aws
}
