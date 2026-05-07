# Output Type Constraints

**New in Terraform 1.15+**

Objective: Learn how to use explicit type constraints on output blocks to ensure type safety and catch errors early.

## Table of Contents

1. [Overview](#overview)
2. [Why Output Type Constraints?](#why-output-type-constraints)
3. [Syntax](#syntax)
4. [Use Cases](#use-cases)
5. [Instructions](#instructions)
6. [Best Practices](#best-practices)
7. [Common Patterns](#common-patterns)

## Overview

Terraform 1.15 introduces the ability to specify explicit type constraints on `output` blocks, similar to how you can constrain variable types. This ensures that output values match expected types and helps catch type mismatches early in the development process.

### What's New

**Before Terraform 1.15** (No type checking):
```hcl
output "instance_id" {
  description = "The instance ID"
  value       = aws_instance.example.id  # No type validation
}
```

**Terraform 1.15+** (With type constraints):
```hcl
output "instance_id" {
  description = "The instance ID"
  type        = string  # Explicit type constraint
  value       = aws_instance.example.id
}
```

## Why Output Type Constraints?

### Problems This Solves

1. **Type Safety**: Catch type mismatches at plan time, not apply time
2. **Documentation**: Self-documenting output types
3. **Module Contracts**: Enforce output type contracts in modules
4. **Refactoring Safety**: Detect breaking changes when refactoring
5. **Consumer Protection**: Protect output consumers from unexpected type changes
6. **Early Error Detection**: Find type issues before they cause problems

### Benefits

- ✅ **Catch errors early** - Type mismatches detected at plan time
- ✅ **Better documentation** - Output types are explicit and clear
- ✅ **Safer refactoring** - Type changes are caught immediately
- ✅ **Module contracts** - Enforce type guarantees for module outputs
- ✅ **IDE support** - Better autocomplete and validation in IDEs
- ✅ **Team collaboration** - Clear expectations for output types

## Syntax

### Basic Type Constraints

```hcl
output "name" {
  description = "Description"
  type        = string  # Type constraint
  value       = "value"
}
```

### Supported Types

```hcl
# Primitive types
output "string_output" {
  type  = string
  value = "hello"
}

output "number_output" {
  type  = number
  value = 42
}

output "bool_output" {
  type  = bool
  value = true
}

# Collection types
output "list_output" {
  type  = list(string)
  value = ["a", "b", "c"]
}

output "set_output" {
  type  = set(number)
  value = [1, 2, 3]
}

output "map_output" {
  type  = map(string)
  value = {
    key1 = "value1"
    key2 = "value2"
  }
}

# Complex types
output "object_output" {
  type = object({
    name = string
    age  = number
  })
  value = {
    name = "Alice"
    age  = 30
  }
}

output "tuple_output" {
  type  = tuple([string, number, bool])
  value = ["hello", 42, true]
}
```

## Use Cases

### Use Case 1: Module Output Contracts

Ensure module outputs maintain their type contracts:

```hcl
# Module outputs with type constraints
output "vpc_id" {
  description = "VPC ID"
  type        = string
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
  value       = aws_subnet.private[*].id
}

output "vpc_config" {
  description = "Complete VPC configuration"
  type = object({
    vpc_id     = string
    cidr_block = string
    subnet_ids = list(string)
  })
  value = {
    vpc_id     = aws_vpc.main.id
    cidr_block = aws_vpc.main.cidr_block
    subnet_ids = aws_subnet.private[*].id
  }
}
```

### Use Case 2: Preventing Type Mismatches

Catch type errors early:

```hcl
locals {
  # This might accidentally be a number
  port = 8080
}

output "application_port" {
  description = "Application port"
  type        = string  # Will fail if port is not a string
  value       = local.port
}

# Fix: Convert to string
output "application_port_fixed" {
  description = "Application port"
  type        = string
  value       = tostring(local.port)
}
```

### Use Case 3: Complex Data Structures

Enforce structure for complex outputs:

```hcl
output "database_config" {
  description = "Database configuration"
  type = object({
    endpoint = string
    port     = number
    username = string
    database = string
    ssl      = bool
    tags     = map(string)
  })
  value = {
    endpoint = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    username = aws_db_instance.main.username
    database = aws_db_instance.main.db_name
    ssl      = true
    tags     = aws_db_instance.main.tags
  }
}
```

### Use Case 4: Optional Attributes

Use optional attributes in object types:

```hcl
output "server_config" {
  description = "Server configuration with optional fields"
  type = object({
    hostname = string
    port     = number
    ssl      = optional(bool, false)      # Optional with default
    timeout  = optional(number)           # Optional without default
    tags     = optional(map(string), {})  # Optional with empty map default
  })
  value = {
    hostname = "example.com"
    port     = 443
    ssl      = true
    # timeout is omitted - will be null
    # tags is omitted - will be {}
  }
}
```

### Use Case 5: List of Objects

Ensure consistent structure in lists:

```hcl
output "instances" {
  description = "List of instance configurations"
  type = list(object({
    id         = string
    name       = string
    ip_address = string
    state      = string
  }))
  value = [
    for instance in aws_instance.servers : {
      id         = instance.id
      name       = instance.tags["Name"]
      ip_address = instance.private_ip
      state      = instance.instance_state
    }
  ]
}
```

### Use Case 6: Map of Objects

Structured maps with type safety:

```hcl
output "environments" {
  description = "Environment configurations"
  type = map(object({
    vpc_id     = string
    subnet_ids = list(string)
    region     = string
  }))
  value = {
    dev = {
      vpc_id     = aws_vpc.dev.id
      subnet_ids = aws_subnet.dev[*].id
      region     = "us-east-1"
    }
    prod = {
      vpc_id     = aws_vpc.prod.id
      subnet_ids = aws_subnet.prod[*].id
      region     = "us-west-2"
    }
  }
}
```

## Instructions

### Task 1: Basic Type Constraints

Create outputs with basic type constraints:

```hcl
# outputs.tf
output "application_name" {
  description = "Name of the application"
  type        = string
  value       = "my-app"
}

output "port_number" {
  description = "Application port"
  type        = number
  value       = 8080
}

output "is_production" {
  description = "Whether this is production"
  type        = bool
  value       = var.environment == "prod"
}
```

### Task 2: Collection Type Constraints

```hcl
output "allowed_ips" {
  description = "List of allowed IP addresses"
  type        = list(string)
  value       = ["10.0.0.0/8", "172.16.0.0/12"]
}

output "environment_tags" {
  description = "Tags for the environment"
  type        = map(string)
  value = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

output "unique_ports" {
  description = "Set of unique ports"
  type        = set(number)
  value       = [80, 443, 8080]
}
```

### Task 3: Object Type Constraints

```hcl
output "application_config" {
  description = "Complete application configuration"
  type = object({
    name        = string
    version     = string
    port        = number
    enabled     = bool
    endpoints   = list(string)
    settings    = map(string)
  })
  value = {
    name      = "my-app"
    version   = "1.0.0"
    port      = 8080
    enabled   = true
    endpoints = ["/api", "/health"]
    settings = {
      log_level = "info"
      timeout   = "30s"
    }
  }
}
```

### Task 4: Nested Object Types

```hcl
output "infrastructure" {
  description = "Complete infrastructure configuration"
  type = object({
    network = object({
      vpc_id     = string
      cidr_block = string
      subnets = list(object({
        id   = string
        cidr = string
        az   = string
      }))
    })
    compute = object({
      instance_type = string
      count         = number
      ami_id        = string
    })
  })
  value = {
    network = {
      vpc_id     = "vpc-12345"
      cidr_block = "10.0.0.0/16"
      subnets = [
        {
          id   = "subnet-1"
          cidr = "10.0.1.0/24"
          az   = "us-east-1a"
        },
        {
          id   = "subnet-2"
          cidr = "10.0.2.0/24"
          az   = "us-east-1b"
        }
      ]
    }
    compute = {
      instance_type = "t3.micro"
      count         = 2
      ami_id        = "ami-12345"
    }
  }
}
```

### Task 5: Type Conversion

Handle type conversions when needed:

```hcl
locals {
  port = 8080  # number
}

output "port_as_string" {
  description = "Port number as string"
  type        = string
  value       = tostring(local.port)
}

output "port_as_number" {
  description = "Port number"
  type        = number
  value       = local.port
}
```

## Best Practices

### 1. Always Use Type Constraints in Modules

✅ **Good** - Explicit type contracts:
```hcl
output "vpc_id" {
  description = "VPC ID"
  type        = string
  value       = aws_vpc.main.id
}
```

❌ **Avoid** - No type constraint:
```hcl
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id  # Type not enforced
}
```

### 2. Use Specific Types

✅ **Good** - Specific type:
```hcl
output "subnet_ids" {
  type  = list(string)
  value = aws_subnet.private[*].id
}
```

❌ **Avoid** - Generic type:
```hcl
output "subnet_ids" {
  type  = list(any)  # Too permissive
  value = aws_subnet.private[*].id
}
```

### 3. Document Complex Types

```hcl
output "database_config" {
  description = <<-EOT
    Database configuration object containing:
    - endpoint: Database endpoint URL
    - port: Database port number
    - credentials: Object with username and password
  EOT
  type = object({
    endpoint = string
    port     = number
    credentials = object({
      username = string
      password = string
    })
  })
  value = {
    endpoint = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    credentials = {
      username = aws_db_instance.main.username
      password = aws_db_instance.main.password
    }
  }
  sensitive = true
}
```

### 4. Use Optional for Flexibility

```hcl
output "config" {
  type = object({
    required_field = string
    optional_field = optional(string)
    optional_with_default = optional(string, "default")
  })
  value = {
    required_field = "value"
    # optional_field can be omitted
    # optional_with_default will be "default" if omitted
  }
}
```

### 5. Validate Type Conversions

```hcl
locals {
  raw_value = "123"
}

output "validated_number" {
  description = "Validated number from string"
  type        = number
  value       = tonumber(local.raw_value)
}
```

### 6. Use Consistent Naming

```hcl
# Good naming convention
output "vpc_id" {
  type = string
  # ...
}

output "vpc_ids" {  # Plural for lists
  type = list(string)
  # ...
}

output "vpc_config" {  # _config suffix for objects
  type = object({...})
  # ...
}
```

## Common Patterns

### Pattern 1: Resource Outputs

```hcl
output "instance" {
  description = "Instance details"
  type = object({
    id         = string
    arn        = string
    public_ip  = string
    private_ip = string
  })
  value = {
    id         = aws_instance.main.id
    arn        = aws_instance.main.arn
    public_ip  = aws_instance.main.public_ip
    private_ip = aws_instance.main.private_ip
  }
}
```

### Pattern 2: Connection Information

```hcl
output "connection_info" {
  description = "Connection information"
  type = object({
    host     = string
    port     = number
    protocol = string
    url      = string
  })
  value = {
    host     = aws_lb.main.dns_name
    port     = 443
    protocol = "https"
    url      = "https://${aws_lb.main.dns_name}"
  }
}
```

### Pattern 3: Multi-Resource Summary

```hcl
output "infrastructure_summary" {
  description = "Summary of all infrastructure"
  type = object({
    vpc = object({
      id   = string
      cidr = string
    })
    instances = list(object({
      id   = string
      type = string
    }))
    databases = map(object({
      endpoint = string
      port     = number
    }))
  })
  value = {
    vpc = {
      id   = aws_vpc.main.id
      cidr = aws_vpc.main.cidr_block
    }
    instances = [
      for i in aws_instance.servers : {
        id   = i.id
        type = i.instance_type
      }
    ]
    databases = {
      for k, db in aws_db_instance.databases : k => {
        endpoint = db.endpoint
        port     = db.port
      }
    }
  }
}
```

## Testing Considerations

### Testing with terraform_data Resources

When testing outputs that depend on `terraform_data` or other resources with unknown values during plan, you must use `command = apply` in your test blocks:

**❌ This will FAIL** (unknown values during plan):
```hcl
# tests/basic.tftest.hcl
run "test_output" {
  command = plan  # ERROR: Values unknown during plan
  
  assert {
    condition     = output.database_config.port == 5432
    error_message = "Port should be 5432"
  }
}
```

**Error message**:
```
Condition expression could not be evaluated at this time. This means you
have executed a `run` block with `command = plan` and one of the values
your condition depended on is not known until after the plan has been
applied.
```

**✅ This WORKS** (values known after apply):
```hcl
# tests/basic.tftest.hcl
run "test_output" {
  command = apply  # OK: Values known after apply
  
  assert {
    condition     = output.database_config.port == 5432
    error_message = "Port should be 5432"
  }
}
```

### When to Use plan vs apply

- **Use `command = plan`**: When testing outputs from data sources or static values
- **Use `command = apply`**: When testing outputs from resources (especially `terraform_data`)

```hcl
# Static output - can use plan
run "test_static_output" {
  command = plan
  
  assert {
    condition     = output.environment == "dev"
    error_message = "Environment should be dev"
  }
}

# Resource output - must use apply
run "test_resource_output" {
  command = apply
  
  assert {
    condition     = output.instance_id != ""
    error_message = "Instance ID should not be empty"
  }
}
```


## Summary

Output type constraints in Terraform 1.15+ provide:

- ✅ **Type safety** - Catch type mismatches early
- ✅ **Documentation** - Self-documenting output types
- ✅ **Module contracts** - Enforce type guarantees
- ✅ **Refactoring safety** - Detect breaking changes
- ✅ **Better tooling** - Improved IDE support

Use type constraints to:
- Enforce module output contracts
- Catch type errors at plan time
- Document expected output types
- Protect output consumers
- Enable safer refactoring

---

**Version Requirements**: Terraform >= 1.15.0  
**Related Topics**: [Input Validation](../1-variable-conditions/README.md), [Advanced Functions](../2-advanced-functions/README.md)  
**Next**: [Pre/Post Conditions](../../TF-302-conditions-checks/README.md)