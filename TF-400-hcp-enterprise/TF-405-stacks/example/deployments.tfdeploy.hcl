# Deployment configurations for the web application stack
# Each deployment represents an instance of the stack (like a workspace)

# Identity token for OIDC authentication with AWS
# This enables dynamic credentials without storing long-lived secrets
identity_token "aws" {
  audience = ["aws.workload.identity"]
}

# Development deployment - us-east-1, minimal resources
deployment "dev" {
  inputs = {
    region            = "us-east-1"
    environment       = "dev"
    instance_type     = "t3.micro"
    db_instance_class = "db.t3.micro"
  }
}

# Staging deployment - us-east-1, moderate resources
deployment "staging" {
  inputs = {
    region            = "us-east-1"
    environment       = "staging"
    instance_type     = "t3.small"
    db_instance_class = "db.t3.small"
  }
}

# Production deployment - us-east-1, production-grade resources
deployment "prod-us-east" {
  inputs = {
    region            = "us-east-1"
    environment       = "prod"
    instance_type     = "t3.medium"
    db_instance_class = "db.t3.medium"
  }
}

# Production deployment - us-west-2, production-grade resources
# Multi-region production deployment for high availability
deployment "prod-us-west" {
  inputs = {
    region            = "us-west-2"
    environment       = "prod"
    instance_type     = "t3.medium"
    db_instance_class = "db.t3.medium"
  }
}

# Production deployment - eu-west-1, production-grade resources
# European region for GDPR compliance and low latency
deployment "prod-eu-west" {
  inputs = {
    region            = "eu-west-1"
    environment       = "prod"
    instance_type     = "t3.medium"
    db_instance_class = "db.t3.medium"
  }
}