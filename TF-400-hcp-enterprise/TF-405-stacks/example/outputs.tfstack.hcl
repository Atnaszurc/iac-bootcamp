# Stack-level outputs
# These outputs aggregate information from all components

output "vpc_id" {
  type        = string
  description = "VPC ID created by the networking component"
  value       = component.networking.vpc_id
}

output "application_url" {
  type        = string
  description = "Load balancer URL for the application"
  value       = component.compute.load_balancer_dns
}

output "database_endpoint" {
  type        = string
  description = "RDS database endpoint"
  value       = component.database.endpoint
  sensitive   = true
}

output "database_secret_arn" {
  type        = string
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = component.database.secret_arn
}

output "deployment_info" {
  type = object({
    environment = string
    region      = string
    vpc_id      = string
  })
  description = "Deployment information summary"
  value = {
    environment = var.environment
    region      = var.region
    vpc_id      = component.networking.vpc_id
  }
}