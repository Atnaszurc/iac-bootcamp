# ============================================================================
# Example 1: Basic Type Constraints
# ============================================================================

output "application_name" {
  description = "Name of the application"
  type        = string
  value       = var.app_name
}

output "port_number" {
  description = "Application port"
  type        = number
  value       = var.port
}

output "is_enabled" {
  description = "Whether the application is enabled"
  type        = bool
  value       = var.enabled
}

output "is_production" {
  description = "Whether this is production environment"
  type        = bool
  value       = var.environment == "prod"
}

# ============================================================================
# Example 2: Collection Type Constraints
# ============================================================================

output "allowed_ports" {
  description = "List of allowed ports"
  type        = list(number)
  value       = [80, 443, var.port]
}

output "instance_ids" {
  description = "List of instance IDs"
  type        = list(string)
  value       = [for i in terraform_data.instances : i.output.id]
}

output "environment_tags" {
  description = "Tags for the environment"
  type        = map(string)
  value = {
    Environment = var.environment
    Application = var.app_name
    ManagedBy   = "Terraform"
    Version     = var.app_version
  }
}

output "unique_ports" {
  description = "Set of unique ports"
  type        = set(number)
  value       = toset([80, 443, var.port, 8080, 3000])
}

# ============================================================================
# Example 3: Simple Object Type Constraints
# ============================================================================

output "application_config" {
  description = "Complete application configuration"
  type = object({
    name        = string
    version     = string
    port        = number
    enabled     = bool
    environment = string
  })
  value = {
    name        = var.app_name
    version     = var.app_version
    port        = var.port
    enabled     = var.enabled
    environment = var.environment
  }
}

output "database_config" {
  description = "Database configuration"
  type = object({
    endpoint = string
    port     = number
    username = string
    database = string
    ssl      = bool
  })
  value = terraform_data.database.output
}

# ============================================================================
# Example 4: List of Objects
# ============================================================================

output "instances" {
  description = "List of instance configurations"
  type = list(object({
    id         = string
    name       = string
    ip_address = string
    state      = string
    type       = string
  }))
  value = [for i in terraform_data.instances : i.output]
}

output "instance_summary" {
  description = "Summary of instances"
  type = list(object({
    id   = string
    name = string
  }))
  value = [
    for i in terraform_data.instances : {
      id   = i.output.id
      name = i.output.name
    }
  ]
}

# ============================================================================
# Example 5: Map of Objects
# ============================================================================

output "instances_by_id" {
  description = "Instances indexed by ID"
  type = map(object({
    name       = string
    ip_address = string
    state      = string
  }))
  value = {
    for i in terraform_data.instances : i.output.id => {
      name       = i.output.name
      ip_address = i.output.ip_address
      state      = i.output.state
    }
  }
}

output "environment_config" {
  description = "Configuration per environment"
  type = map(object({
    port    = number
    enabled = bool
  }))
  value = {
    dev = {
      port    = 8080
      enabled = true
    }
    staging = {
      port    = 8081
      enabled = true
    }
    prod = {
      port    = 443
      enabled = var.environment == "prod"
    }
  }
}

# ============================================================================
# Example 6: Nested Object Types
# ============================================================================

output "infrastructure" {
  description = "Complete infrastructure configuration"
  type = object({
    application = object({
      name    = string
      version = string
      port    = number
    })
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
      instance_type  = string
      instance_count = number
      instances = list(object({
        id   = string
        name = string
      }))
    })
  })
  value = {
    application = {
      name    = var.app_name
      version = var.app_version
      port    = var.port
    }
    network = {
      vpc_id     = terraform_data.network.output.vpc_id
      cidr_block = terraform_data.network.output.cidr_block
      subnets    = terraform_data.network.output.subnets
    }
    compute = {
      instance_type  = var.instance_type
      instance_count = var.instance_count
      instances = [
        for i in terraform_data.instances : {
          id   = i.output.id
          name = i.output.name
        }
      ]
    }
  }
}

output "network_config" {
  description = "Network configuration with nested objects"
  type = object({
    vpc = object({
      id   = string
      cidr = string
    })
    subnets = list(object({
      id   = string
      cidr = string
      az   = string
    }))
  })
  value = {
    vpc = {
      id   = terraform_data.network.output.vpc_id
      cidr = terraform_data.network.output.cidr_block
    }
    subnets = terraform_data.network.output.subnets
  }
}

# ============================================================================
# Example 7: Optional Attributes
# ============================================================================

output "server_config" {
  description = "Server configuration with optional fields"
  type = object({
    hostname = string
    port     = number
    ssl      = optional(bool, false)
    timeout  = optional(number)
    tags     = optional(map(string), {})
  })
  value = {
    hostname = "${var.app_name}.example.com"
    port     = var.port
    ssl      = var.environment == "prod"
    # timeout is omitted - will be null
    tags = {
      Environment = var.environment
      Application = var.app_name
    }
  }
}

output "database_connection" {
  description = "Database connection with optional SSL config"
  type = object({
    host     = string
    port     = number
    database = string
    ssl = optional(object({
      enabled  = bool
      cert_path = optional(string)
    }), {
      enabled = false
    })
  })
  value = {
    host     = terraform_data.database.output.endpoint
    port     = terraform_data.database.output.port
    database = terraform_data.database.output.database
    ssl = {
      enabled   = terraform_data.database.output.ssl
      cert_path = "/etc/ssl/certs/db.pem"
    }
  }
}

# ============================================================================
# Example 8: Connection Information
# ============================================================================

output "connection_info" {
  description = "Connection information for the application"
  type = object({
    host     = string
    port     = number
    protocol = string
    url      = string
  })
  value = {
    host     = terraform_data.load_balancer.output.dns_name
    port     = terraform_data.load_balancer.output.port
    protocol = terraform_data.load_balancer.output.protocol
    url      = "https://${terraform_data.load_balancer.output.dns_name}"
  }
}

output "endpoints" {
  description = "Application endpoints"
  type = map(object({
    url      = string
    port     = number
    protocol = string
  }))
  value = {
    api = {
      url      = "https://${terraform_data.load_balancer.output.dns_name}/api"
      port     = 443
      protocol = "HTTPS"
    }
    health = {
      url      = "https://${terraform_data.load_balancer.output.dns_name}/health"
      port     = 443
      protocol = "HTTPS"
    }
    metrics = {
      url      = "https://${terraform_data.load_balancer.output.dns_name}/metrics"
      port     = 443
      protocol = "HTTPS"
    }
  }
}

# ============================================================================
# Example 9: Type Conversion Examples
# ============================================================================

output "port_as_string" {
  description = "Port number as string"
  type        = string
  value       = tostring(var.port)
}

output "port_as_number" {
  description = "Port number"
  type        = number
  value       = var.port
}

output "enabled_as_string" {
  description = "Enabled flag as string"
  type        = string
  value       = tostring(var.enabled)
}

# ============================================================================
# Example 10: Tuple Type
# ============================================================================

output "version_tuple" {
  description = "Version information as list"
  type        = list(string)
  value       = split(".", var.app_version)
}

output "config_tuple" {
  description = "Configuration as tuple"
  type        = tuple([string, number, bool])
  value       = [var.app_name, var.port, var.enabled]
}

# ============================================================================
# Example 11: Complex Real-World Example
# ============================================================================

output "deployment_info" {
  description = "Complete deployment information"
  type = object({
    metadata = object({
      name        = string
      version     = string
      environment = string
      timestamp   = string
    })
    infrastructure = object({
      network = object({
        vpc_id  = string
        subnets = list(string)
      })
      compute = object({
        instance_count = number
        instance_type  = string
        instances      = list(string)
      })
      database = object({
        endpoint = string
        port     = number
      })
    })
    connectivity = object({
      load_balancer = object({
        dns_name = string
        url      = string
      })
      endpoints = map(string)
    })
  })
  value = {
    metadata = {
      name        = var.app_name
      version     = var.app_version
      environment = var.environment
      timestamp   = timestamp()
    }
    infrastructure = {
      network = {
        vpc_id  = terraform_data.network.output.vpc_id
        subnets = [for s in terraform_data.network.output.subnets : s.id]
      }
      compute = {
        instance_count = var.instance_count
        instance_type  = var.instance_type
        instances      = [for i in terraform_data.instances : i.output.id]
      }
      database = {
        endpoint = terraform_data.database.output.endpoint
        port     = terraform_data.database.output.port
      }
    }
    connectivity = {
      load_balancer = {
        dns_name = terraform_data.load_balancer.output.dns_name
        url      = "https://${terraform_data.load_balancer.output.dns_name}"
      }
      endpoints = {
        api     = "https://${terraform_data.load_balancer.output.dns_name}/api"
        health  = "https://${terraform_data.load_balancer.output.dns_name}/health"
        metrics = "https://${terraform_data.load_balancer.output.dns_name}/metrics"
      }
    }
  }
}

# ============================================================================
# Example 12: Sensitive Output with Type Constraint
# ============================================================================

output "database_credentials" {
  description = "Database credentials (sensitive)"
  type = object({
    username = string
    password = string
    endpoint = string
  })
  value = {
    username = terraform_data.database.output.username
    password = "super-secret-password"  # In real scenario, from secure source
    endpoint = terraform_data.database.output.endpoint
  }
  sensitive = true
}