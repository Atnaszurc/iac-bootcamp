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

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "aws203"
}

variable "ebs_size_gb" {
  description = "Size of the EBS data volume in GB"
  type        = number
  default     = 20
}