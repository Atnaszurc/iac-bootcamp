variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}