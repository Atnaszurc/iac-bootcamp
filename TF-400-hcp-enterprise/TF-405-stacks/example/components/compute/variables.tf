variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where resources will be created"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet IDs for the load balancer"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet IDs for the application servers"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for application servers"
}

variable "db_endpoint" {
  type        = string
  description = "Database endpoint for application configuration"
}

variable "db_secret_arn" {
  type        = string
  description = "ARN of the Secrets Manager secret containing database credentials"
}