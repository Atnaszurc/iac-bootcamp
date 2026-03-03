# TF-405 Terraform Stacks Example

This example demonstrates a complete **Terraform Stack** that deploys a multi-component web application across multiple environments and regions.

## 🎯 What This Example Shows

- **Stack Definition** (`.tfstack.hcl`) - Defines 3 components with dependencies
- **Deployments** (`.tfdeploy.hcl`) - 5 deployment instances (dev, staging, 3x prod)
- **Component Architecture** - Networking → Database → Compute
- **OIDC Authentication** - Dynamic AWS credentials without long-lived secrets
- **Multi-Region** - Same stack deployed to us-east-1, us-west-2, eu-west-1

## 📁 Structure

```
example/
├── stack.tfstack.hcl           # Stack definition with components
├── outputs.tfstack.hcl         # Stack-level outputs
├── deployments.tfdeploy.hcl    # Deployment configurations
│
└── components/                 # Component configurations
    ├── networking/             # VPC, subnets, security groups
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── database/               # RDS PostgreSQL + Secrets Manager
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── compute/                # ALB, Auto Scaling, EC2 instances
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── user-data.sh
```

## 🔧 Components

### 1. Networking Component
Creates the network foundation:
- VPC with public and private subnets (2 AZs)
- Internet Gateway and NAT Gateway
- Route tables
- Security groups for ALB, app servers, and database

**Outputs**: `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, security group IDs

### 2. Database Component
Creates the database layer:
- RDS PostgreSQL instance
- DB subnet group
- Secrets Manager secret for credentials
- Automated backups (7 days for prod, 1 day for dev/staging)
- Multi-AZ for production

**Outputs**: `endpoint`, `address`, `port`, `secret_arn`, `db_name`

**Dependencies**: Requires networking component (VPC, subnets)

### 3. Compute Component
Creates the application layer:
- Application Load Balancer (public subnets)
- Auto Scaling Group (private subnets)
- Launch Template with user data
- Target Group with health checks
- Scales based on environment (1-2 for dev, 2-6 for prod)

**Outputs**: `load_balancer_dns`, `load_balancer_arn`, `target_group_arn`

**Dependencies**: Requires networking and database components

## 🚀 Deployments

The stack defines 5 deployments:

| Deployment | Region | Environment | Instance Type | DB Class |
|------------|--------|-------------|---------------|----------|
| `dev` | us-east-1 | dev | t3.micro | db.t3.micro |
| `staging` | us-east-1 | staging | t3.small | db.t3.small |
| `prod-us-east` | us-east-1 | prod | t3.medium | db.t3.medium |
| `prod-us-west` | us-west-2 | prod | t3.medium | db.t3.medium |
| `prod-eu-west` | eu-west-1 | prod | t3.medium | db.t3.medium |

## ⚠️ Requirements

> **This example requires HCP Terraform with Stacks enabled.**
>
> - Terraform 1.13+
> - HCP Terraform account (free tier may not include Stacks)
> - AWS account with appropriate permissions
> - OIDC configured between HCP Terraform and AWS

## 📝 How to Use

### 1. Prerequisites

```bash
# Authenticate with HCP Terraform
terraform login

# Ensure your HCP Terraform organization has Stacks enabled
# Check: https://app.terraform.io/app/<your-org>/settings/general
```

### 2. Configure OIDC (One-Time Setup)

Follow the [HCP Terraform OIDC guide](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration) to:
1. Create an IAM role in AWS
2. Configure trust relationship with HCP Terraform
3. Note the role ARN for deployment configuration

### 3. Validate the Stack

```bash
cd example/
terraform stacks validate
```

### 4. Plan Deployments

```bash
# Plan all deployments
terraform stacks plan

# Plan a specific deployment
terraform stacks plan -deployment=dev
```

### 5. Apply Deployments

```bash
# Apply all deployments (will prompt for confirmation)
terraform stacks apply

# Apply a specific deployment
terraform stacks apply -deployment=dev

# Apply with auto-approve
terraform stacks apply -deployment=dev -auto-approve
```

### 6. View Stack Status

```bash
# Show overall stack status
terraform stacks show

# List all deployments
terraform stacks deployments list

# Show specific deployment
terraform stacks deployments show dev
```

### 7. Access the Application

After deployment, get the load balancer URL:

```bash
# From stack outputs
terraform stacks outputs

# The application_url output will show the ALB DNS name
# Example: dev-alb-1234567890.us-east-1.elb.amazonaws.com
```

## 🔍 Key Concepts Demonstrated

### Component Dependencies

```hcl
component "compute" {
  # ...
  depends_on = [
    component.networking,
    component.database
  ]
}
```

Stacks automatically handle the dependency graph, ensuring components are created in the correct order.

### Component Output References

```hcl
component "database" {
  inputs = {
    vpc_id     = component.networking.vpc_id
    subnet_ids = component.networking.private_subnet_ids
  }
}
```

Components can reference outputs from other components, creating a data flow through the stack.

### Environment-Specific Configuration

```hcl
deployment "dev" {
  inputs = {
    region        = "us-east-1"
    environment   = "dev"
    instance_type = "t3.micro"
  }
}

deployment "prod-us-east" {
  inputs = {
    region        = "us-east-1"
    environment   = "prod"
    instance_type = "t3.medium"
  }
}
```

Same stack definition, different configurations per deployment.

### Provider Configuration in Stacks

```hcl
provider "aws" "main" {
  config {
    region = var.region
    
    default_tags {
      tags = {
        Environment = var.environment
        ManagedBy   = "Terraform-Stacks"
      }
    }
  }
}
```

Providers are declared at the stack level and passed to components.

## 🧹 Cleanup

```bash
# Destroy a specific deployment
terraform stacks destroy -deployment=dev

# Destroy all deployments (use with caution!)
terraform stacks destroy
```

## 📚 Learn More

- [Terraform Stacks Documentation](https://developer.hashicorp.com/terraform/language/stacks)
- [HCP Terraform Stacks](https://developer.hashicorp.com/terraform/cloud-docs/stacks)
- [TF-405 Course README](../README.md)

## 💡 Tips

1. **Start with dev**: Test the stack with the `dev` deployment first
2. **Use -target**: Target specific components during development
3. **Check dependencies**: Use `terraform stacks show` to visualize the dependency graph
4. **Monitor costs**: Each deployment creates real AWS resources
5. **OIDC is recommended**: Avoid storing long-lived AWS credentials

## ⚠️ Important Notes

- This example creates **real AWS resources** that incur costs
- Production deployments have deletion protection enabled
- Database backups are configured (7 days for prod)
- Multi-AZ is enabled for production databases
- Auto Scaling is configured (1-2 instances for dev, 2-6 for prod)

---

**Part of the [Hashi-Training](../../../../README.md) curriculum — TF-405: Terraform Stacks**