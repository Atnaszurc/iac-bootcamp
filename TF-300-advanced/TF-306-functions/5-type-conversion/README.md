# Type Conversion with convert() Function

**New in Terraform 1.15+**

Objective: Learn how to use the `convert()` function for precise inline type conversions with explicit type constraints.

## Table of Contents

1. [Overview](#overview)
2. [Why Use convert()?](#why-use-convert)
3. [Syntax](#syntax)
4. [Instructions](#instructions)
5. [Common Use Cases](#common-use-cases)
6. [Comparison with Other Functions](#comparison-with-other-functions)
7. [Best Practices](#best-practices)

## Overview

Terraform 1.15 introduces the `convert()` function, which provides precise control over type conversions with explicit type constraints. Unlike traditional type conversion functions (`tonumber`, `tostring`, etc.), `convert()` allows you to specify complex type constraints including objects, tuples, and nested structures.

## Why Use convert()?

### Problems convert() Solves

1. **Complex Type Conversions**: Convert to object types with specific structures
2. **Type Safety**: Explicit type constraints catch errors early
3. **API Response Parsing**: Convert dynamic API responses to known types
4. **Variable Transformation**: Transform variables to match module requirements
5. **Configuration Validation**: Ensure data matches expected structure

### Benefits

- ✅ **Explicit Type Constraints**: Specify exact type structure
- ✅ **Better Error Messages**: Clear feedback when conversion fails
- ✅ **Type Safety**: Catch type mismatches at plan time
- ✅ **Complex Types**: Support for objects, tuples, maps, sets
- ✅ **Nested Structures**: Handle deeply nested type conversions

## Syntax

```hcl
convert(value, type_constraint)
```

**Parameters**:
- `value`: The value to convert
- `type_constraint`: The target type (string, number, bool, list, map, object, etc.)

**Returns**: The value converted to the specified type

## Instructions

### Task 1: Basic Type Conversions

```hcl
locals {
  # String to number
  port_string = "8080"
  port_number = convert(local.port_string, number)  # 8080
  
  # Number to string
  count_number = 5
  count_string = convert(local.count_number, string)  # "5"
  
  # String to bool
  enabled_string = "true"
  enabled_bool   = convert(local.enabled_string, bool)  # true
  
  # List of strings to set of strings
  tags_list = ["web", "api", "web"]  # duplicates
  tags_set  = convert(local.tags_list, set(string))  # ["web", "api"]
}
```

### Task 2: Object Type Conversions

```hcl
locals {
  # Raw configuration (from API, file, etc.)
  raw_config = {
    name    = "my-app"
    port    = "8080"  # string
    enabled = "true"  # string
    count   = "3"     # string
  }
  
  # Convert to typed object
  typed_config = convert(local.raw_config, object({
    name    = string
    port    = number
    enabled = bool
    count   = number
  }))
  
  # Now typed_config.port is number 8080, not string "8080"
  # typed_config.enabled is bool true, not string "true"
}
```

### Task 3: List and Map Conversions

```hcl
locals {
  # Convert list of strings to list of numbers
  string_ports = ["80", "443", "8080"]
  number_ports = convert(local.string_ports, list(number))  # [80, 443, 8080]
  
  # Convert map with string values to map with number values
  string_limits = {
    cpu    = "2"
    memory = "4096"
    disk   = "100"
  }
  number_limits = convert(local.string_limits, map(number))
  # { cpu = 2, memory = 4096, disk = 100 }
  
  # Convert to specific object structure
  resource_limits = convert(local.string_limits, object({
    cpu    = number
    memory = number
    disk   = number
  }))
}
```

### Task 4: Complex Nested Structures

```hcl
locals {
  # Raw server configuration
  raw_servers = {
    web = {
      count = "3"
      size  = "small"
      ports = ["80", "443"]
    }
    api = {
      count = "2"
      size  = "medium"
      ports = ["8080", "8443"]
    }
  }
  
  # Convert to typed structure
  typed_servers = convert(local.raw_servers, map(object({
    count = number
    size  = string
    ports = list(number)
  })))
  
  # Now typed_servers.web.count is number 3
  # typed_servers.web.ports is [80, 443] (numbers)
}
```

### Task 5: API Response Parsing

```hcl
# Simulate API response (all strings)
locals {
  api_response = {
    instance_id   = "i-1234567890"
    instance_type = "t3.micro"
    cpu_count     = "2"
    memory_gb     = "1"
    running       = "true"
    tags          = ["production", "web", "frontend"]
  }
  
  # Convert to proper types
  instance_info = convert(local.api_response, object({
    instance_id   = string
    instance_type = string
    cpu_count     = number
    memory_gb     = number
    running       = bool
    tags          = set(string)
  }))
  
  # Use with type safety
  is_production = contains(local.instance_info.tags, "production")
  total_memory  = local.instance_info.memory_gb * 1024  # Works because it's a number
}
```

### Task 6: Variable Transformation

```hcl
variable "config_json" {
  description = "Configuration as JSON string"
  type        = string
  default     = <<-EOT
    {
      "app_name": "myapp",
      "replicas": "5",
      "enable_monitoring": "true",
      "resources": {
        "cpu": "2",
        "memory": "4096"
      }
    }
  EOT
}

locals {
  # Parse JSON and convert to typed structure
  parsed_config = jsondecode(var.config_json)
  
  typed_config = convert(local.parsed_config, object({
    app_name           = string
    replicas           = number
    enable_monitoring  = bool
    resources = object({
      cpu    = number
      memory = number
    })
  }))
  
  # Now use with type safety
  total_cpu    = local.typed_config.replicas * local.typed_config.resources.cpu
  total_memory = local.typed_config.replicas * local.typed_config.resources.memory
}
```

## Common Use Cases

### Use Case 1: Environment Variable Parsing

```hcl
# Environment variables are always strings
locals {
  env_port    = convert(get_env("APP_PORT", "8080"), number)
  env_debug   = convert(get_env("DEBUG", "false"), bool)
  env_workers = convert(get_env("WORKERS", "4"), number)
}
```

### Use Case 2: Configuration File Processing

```hcl
locals {
  # Load YAML config (returns map with string values)
  yaml_config = yamldecode(file("${path.module}/config.yaml"))
  
  # Convert to typed structure
  app_config = convert(local.yaml_config, object({
    name        = string
    port        = number
    replicas    = number
    enable_tls  = bool
    timeout_sec = number
  }))
}
```

### Use Case 3: Module Input Transformation

```hcl
# Module expects specific types but receives strings
variable "server_config" {
  type = map(string)  # Receives all strings
}

locals {
  # Convert to proper types for internal use
  typed_config = convert(var.server_config, object({
    instance_count = number
    instance_size  = string
    enable_backup  = bool
    backup_retention_days = number
  }))
}

resource "example_server" "this" {
  count          = local.typed_config.instance_count  # number
  size           = local.typed_config.instance_size   # string
  backup_enabled = local.typed_config.enable_backup   # bool
}
```

### Use Case 4: Data Validation

```hcl
variable "user_input" {
  description = "User-provided configuration"
  type        = any
}

locals {
  # Validate and convert user input
  # This will fail at plan time if structure doesn't match
  validated_input = convert(var.user_input, object({
    name     = string
    age      = number
    active   = bool
    tags     = set(string)
    metadata = map(string)
  }))
}
```

## Comparison with Other Functions

### convert() vs tonumber()

```hcl
# tonumber() - Simple conversion
local.port1 = tonumber("8080")  # 8080

# convert() - Explicit type constraint
local.port2 = convert("8080", number)  # 8080

# convert() advantage: Works with complex types
local.config = convert(var.raw, object({
  port = number
  name = string
}))
# tonumber() cannot do this
```

### convert() vs tostring()

```hcl
# tostring() - Simple conversion
local.count_str1 = tostring(5)  # "5"

# convert() - Explicit type constraint
local.count_str2 = convert(5, string)  # "5"

# Both work similarly for primitives
# convert() is more explicit about intent
```

### convert() vs tolist()/toset()/tomap()

```hcl
# Traditional functions
local.list1 = tolist(["a", "b"])
local.set1  = toset(["a", "b", "a"])
local.map1  = tomap({a = "1", b = "2"})

# convert() with explicit element types
local.list2 = convert(["a", "b"], list(string))
local.set2  = convert(["a", "b", "a"], set(string))
local.map2  = convert({a = "1", b = "2"}, map(string))

# convert() advantage: Specify element types
local.number_list = convert(["1", "2", "3"], list(number))
# tolist() cannot convert element types
```

### When to Use Each

| Function | Use When |
|----------|----------|
| `tonumber()`, `tostring()`, `tobool()` | Simple primitive conversions |
| `tolist()`, `toset()`, `tomap()` | Collection type conversions without element type change |
| `convert()` | Complex types, nested structures, element type conversions, explicit validation |

## Best Practices

### 1. Use convert() for Type Safety

✅ **Good** - Explicit type constraints:
```hcl
local.config = convert(var.raw_config, object({
  port    = number
  enabled = bool
}))
```

❌ **Avoid** - Implicit conversions:
```hcl
local.config = var.raw_config  # No type validation
```

### 2. Validate External Data

```hcl
# Always convert external data to known types
locals {
  api_data = convert(data.external.api.result, object({
    id     = string
    count  = number
    active = bool
  }))
}
```

### 3. Document Type Constraints

```hcl
locals {
  # Convert user input to validated structure
  # Expected format: {name: string, replicas: number, enabled: bool}
  validated_input = convert(var.user_config, object({
    name     = string
    replicas = number
    enabled  = bool
  }))
}
```

### 4. Handle Conversion Errors Gracefully

```hcl
# Use try() to handle potential conversion failures
locals {
  safe_config = try(
    convert(var.raw_config, object({
      port = number
      name = string
    })),
    {
      port = 8080
      name = "default"
    }
  )
}
```

### 5. Combine with Validation

```hcl
variable "server_config" {
  type = any
  
  validation {
    condition = can(convert(var.server_config, object({
      count = number
      size  = string
    })))
    error_message = "server_config must have 'count' (number) and 'size' (string)"
  }
}

locals {
  typed_config = convert(var.server_config, object({
    count = number
    size  = string
  }))
}
```

### 6. Use for Module Interfaces

```hcl
# Module that accepts flexible input
variable "resources" {
  description = "Resource configuration (flexible format)"
  type        = any
}

locals {
  # Convert to internal typed structure
  typed_resources = convert(var.resources, map(object({
    count    = number
    size     = string
    enabled  = bool
  })))
}
```

## Testing with terraform console

```bash
# Start terraform console
terraform console

# Test basic conversions
> convert("8080", number)
8080

> convert("true", bool)
true

# Test object conversion
> convert({name = "app", port = "8080"}, object({name = string, port = number}))
{
  "name" = "app"
  "port" = 8080
}

# Test list conversion
> convert(["1", "2", "3"], list(number))
[
  1,
  2,
  3,
]

# Test with complex nested structure
> convert({web = {count = "3", ports = ["80", "443"]}}, map(object({count = number, ports = list(number)})))
{
  "web" = {
    "count" = 3
    "ports" = [
      80,
      443,
    ]
  }
}
```


## Testing Considerations

### Using command = apply in Tests

This module's tests use `command = apply` instead of `command = plan` because the infrastructure resources create values that are unknown until after the apply phase.

**Why apply is required**:
- Resource IDs are generated during creation
- Computed attributes are only known after apply
- Output values depend on created resources

**When to use plan vs apply**:
- **Use `command = plan`**: When testing static values, data sources, or validation logic
- **Use `command = apply`**: When testing resource creation, outputs, or computed values

`hcl
# Example test structure
run "test_infrastructure" {
  command = apply  # Required for resource testing
  
  assert {
    condition     = output.resource_id != ""
    error_message = "Resource ID should be generated"
  }
}
`

**Note**: Using `command = apply` means tests will create actual infrastructure, so ensure proper cleanup in test teardown.
## Summary

The `convert()` function in Terraform 1.15+ provides:

- ✅ **Explicit type conversions** with full type constraint support
- ✅ **Type safety** for external data and API responses
- ✅ **Complex type handling** including objects, tuples, and nested structures
- ✅ **Better error messages** when conversions fail
- ✅ **Validation capabilities** when combined with `can()` and `try()`

Use `convert()` when you need precise control over type conversions, especially for:
- Parsing external configuration files
- Processing API responses
- Validating user inputs
- Transforming data between modules
- Ensuring type safety in dynamic configurations

---

**Version Requirements**: Terraform >= 1.15.0  
**Related Topics**: [Variables](../../../TF-100-fundamentals/TF-102-variables-loops/1-variables/README.md), [Validation](../../TF-301-validation/README.md)  
**Next**: [Main TF-306 README](../README.md)