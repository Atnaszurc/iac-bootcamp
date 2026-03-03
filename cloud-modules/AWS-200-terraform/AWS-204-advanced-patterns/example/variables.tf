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
  default     = "aws204"
}

variable "instance_type" {
  description = "EC2 instance type for ASG instances"
  type        = string
  default     = "t3.micro"
}

variable "asg_desired" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_min" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 4
}