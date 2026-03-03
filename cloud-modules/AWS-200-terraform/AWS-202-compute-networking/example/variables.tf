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
  default     = "aws202"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into instances (use your IP: x.x.x.x/32)"
  type        = string
  default     = "0.0.0.0/0" # Restrict this in production!
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro" # Free tier eligible
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair for SSH access (leave empty to skip)"
  type        = string
  default     = ""
}