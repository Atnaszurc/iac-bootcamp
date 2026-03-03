variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the database will be created"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the database subnet group"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
}

variable "db_name" {
  type        = string
  description = "Name of the database to create"
}