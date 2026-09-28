terraform {
  required_version = ">= 1.15.0"
}

# ============================================================================
# SECTION 1: Basic Type Conversions
# ============================================================================

locals {
  # String to number
  port_string = "8080"
  port_number = convert(local.port_string, number)

  # Number to string
  count_number = 5
  count_string = convert(local.count_number, string)

  # String to bool
  enabled_string = "true"
  enabled_bool   = convert(local.enabled_string, bool)

  # List to set (removes duplicates)
  tags_list = ["web", "api", "web", "frontend"]
  tags_set  = convert(local.tags_list, set(string))
}

# ============================================================================
# SECTION 2: Object Type Conversions
# ============================================================================

locals {
  # Simulate raw configuration from API or file (all strings)
  raw_config = {
    app_name = "my-application"
    port     = "8080"
    enabled  = "true"
    replicas = "3"
    timeout  = "30"
  }

  # Convert to properly typed object
  typed_config = convert(local.raw_config, object({
    app_name = string
    port     = number
    enabled  = bool
    replicas = number
    timeout  = number
  }))

  # Now we can do math with numbers
  total_capacity = local.typed_config.replicas * 100
  port_range     = "${local.typed_config.port}-${local.typed_config.port + 10}"
}

# ============================================================================
# SECTION 3: List and Map Conversions
# ============================================================================

locals {
  # Convert list of string numbers to list of actual numbers
  string_ports = ["80", "443", "8080", "8443"]
  number_ports = convert(local.string_ports, list(number))

  # Convert map with string values to map with number values
  string_limits = {
    cpu_cores = "4"
    memory_gb = "16"
    disk_gb   = "100"
  }
  number_limits = convert(local.string_limits, map(number))

  # Calculate totals (only works because they're numbers now)
  total_memory = local.number_limits.memory_gb * local.typed_config.replicas
  total_disk   = local.number_limits.disk_gb * local.typed_config.replicas
}

# ============================================================================
# SECTION 4: Complex Nested Structures
# ============================================================================

locals {
  # Simulate multi-environment configuration (all strings)
  raw_environments = {
    dev = {
      instance_count   = "2"
      instance_size    = "small"
      ports            = ["8080", "8443"]
      enable_backup    = "false"
      backup_retention = "7"
    }
    staging = {
      instance_count   = "3"
      instance_size    = "medium"
      ports            = ["80", "443"]
      enable_backup    = "true"
      backup_retention = "14"
    }
    prod = {
      instance_count   = "5"
      instance_size    = "large"
      ports            = ["80", "443", "8080"]
      enable_backup    = "true"
      backup_retention = "30"
    }
  }

  # Convert to typed structure
  typed_environments = convert(local.raw_environments, map(object({
    instance_count   = number
    instance_size    = string
    ports            = list(number)
    enable_backup    = bool
    backup_retention = number
  })))

  # Now we can safely use these values
  prod_total_instances = local.typed_environments.prod.instance_count
  prod_primary_port    = local.typed_environments.prod.ports[0]
}

# ============================================================================
# SECTION 5: API Response Simulation
# ============================================================================

locals {
  # Simulate API response (typically all strings)
  api_response = {
    server_id    = "srv-abc123"
    server_name  = "web-server-01"
    cpu_count    = "4"
    memory_gb    = "8"
    disk_gb      = "100"
    is_running   = "true"
    uptime_hours = "720"
    tags         = ["production", "web", "frontend", "web"] # duplicates
  }

  # Convert to proper types
  server_info = convert(local.api_response, object({
    server_id    = string
    server_name  = string
    cpu_count    = number
    memory_gb    = number
    disk_gb      = number
    is_running   = bool
    uptime_hours = number
    tags         = set(string) # set removes duplicates
  }))

  # Calculate derived values (type-safe)
  uptime_days      = local.server_info.uptime_hours / 24
  total_storage_mb = local.server_info.disk_gb * 1024
  memory_per_cpu   = local.server_info.memory_gb / local.server_info.cpu_count
  is_production    = contains(local.server_info.tags, "production")
}

# ============================================================================
# SECTION 6: Configuration File Simulation
# ============================================================================

locals {
  # Simulate YAML/JSON config loaded from file (all strings)
  yaml_config = {
    application = {
      name        = "myapp"
      version     = "1.2.3"
      port        = "8080"
      workers     = "4"
      debug       = "false"
      timeout_sec = "30"
    }
    database = {
      host        = "db.example.com"
      port        = "5432"
      name        = "myapp_db"
      pool_size   = "10"
      ssl_enabled = "true"
    }
  }

  # Convert to typed structure
  app_config = convert(local.yaml_config, object({
    application = object({
      name        = string
      version     = string
      port        = number
      workers     = number
      debug       = bool
      timeout_sec = number
    })
    database = object({
      host        = string
      port        = number
      name        = string
      pool_size   = number
      ssl_enabled = bool
    })
  }))

  # Use with type safety
  connection_string = "${local.app_config.database.host}:${local.app_config.database.port}/${local.app_config.database.name}"
  total_workers     = local.app_config.application.workers * local.typed_config.replicas
}

# ============================================================================
# SECTION 7: Validation with convert()
# ============================================================================

locals {
  # User input that needs validation
  user_input = {
    username = "john_doe"
    age      = "30"
    active   = "true"
    roles    = ["admin", "user", "admin"] # duplicates
    metadata = {
      department = "engineering"
      level      = "senior"
    }
  }

  # Convert and validate structure
  # This will fail at plan time if structure doesn't match
  validated_user = convert(local.user_input, object({
    username = string
    age      = number
    active   = bool
    roles    = set(string) # removes duplicates
    metadata = map(string)
  }))

  # Safe to use
  is_admin = contains(local.validated_user.roles, "admin")
  is_adult = local.validated_user.age >= 18
}

# ============================================================================
# OUTPUT FILES - Demonstrate the conversions
# ============================================================================

resource "local_file" "basic_conversions" {
  content  = <<-EOT
    BASIC TYPE CONVERSIONS
    =====================
    
    String to Number:
      Input:  "${local.port_string}" (string)
      Output: ${local.port_number} (number)
    
    Number to String:
      Input:  ${local.count_number} (number)
      Output: "${local.count_string}" (string)
    
    String to Bool:
      Input:  "${local.enabled_string}" (string)
      Output: ${local.enabled_bool} (bool)
    
    List to Set (removes duplicates):
      Input:  ${jsonencode(local.tags_list)}
      Output: ${jsonencode(local.tags_set)}
  EOT
  filename = "${path.module}/output/01-basic-conversions.txt"
}

resource "local_file" "object_conversions" {
  content  = <<-EOT
    OBJECT TYPE CONVERSIONS
    ======================
    
    Raw Config (all strings):
    ${jsonencode(local.raw_config)}
    
    Typed Config (proper types):
    ${jsonencode(local.typed_config)}
    
    Calculations (only possible with numbers):
      Total Capacity: ${local.total_capacity}
      Port Range: ${local.port_range}
  EOT
  filename = "${path.module}/output/02-object-conversions.txt"
}

resource "local_file" "complex_structures" {
  content  = <<-EOT
    COMPLEX NESTED STRUCTURES
    ========================
    
    Production Environment:
      Instance Count: ${local.prod_total_instances}
      Primary Port: ${local.prod_primary_port}
      Backup Enabled: ${local.typed_environments.prod.enable_backup}
      Retention Days: ${local.typed_environments.prod.backup_retention}
    
    All Environments:
    ${jsonencode(local.typed_environments)}
  EOT
  filename = "${path.module}/output/03-complex-structures.txt"
}

resource "local_file" "api_response" {
  content  = <<-EOT
    API RESPONSE PARSING
    ===================
    
    Server Information:
      ID: ${local.server_info.server_id}
      Name: ${local.server_info.server_name}
      CPUs: ${local.server_info.cpu_count}
      Memory: ${local.server_info.memory_gb} GB
      Disk: ${local.server_info.disk_gb} GB
      Running: ${local.server_info.is_running}
      Tags: ${jsonencode(local.server_info.tags)}
    
    Calculated Values:
      Uptime: ${local.uptime_days} days
      Total Storage: ${local.total_storage_mb} MB
      Memory per CPU: ${local.memory_per_cpu} GB
      Is Production: ${local.is_production}
  EOT
  filename = "${path.module}/output/04-api-response.txt"
}

resource "local_file" "config_file" {
  content  = <<-EOT
    CONFIGURATION FILE PROCESSING
    ============================
    
    Application Config:
      Name: ${local.app_config.application.name}
      Version: ${local.app_config.application.version}
      Port: ${local.app_config.application.port}
      Workers: ${local.app_config.application.workers}
      Debug: ${local.app_config.application.debug}
    
    Database Config:
      Connection: ${local.connection_string}
      Pool Size: ${local.app_config.database.pool_size}
      SSL: ${local.app_config.database.ssl_enabled}
    
    Calculated:
      Total Workers: ${local.total_workers}
  EOT
  filename = "${path.module}/output/05-config-file.txt"
}

resource "local_file" "validation" {
  content  = <<-EOT
    USER INPUT VALIDATION
    ====================
    
    Validated User:
      Username: ${local.validated_user.username}
      Age: ${local.validated_user.age}
      Active: ${local.validated_user.active}
      Roles: ${jsonencode(local.validated_user.roles)}
      Department: ${local.validated_user.metadata.department}
      Level: ${local.validated_user.metadata.level}
    
    Validation Results:
      Is Admin: ${local.is_admin}
      Is Adult: ${local.is_adult}
  EOT
  filename = "${path.module}/output/06-validation.txt"
}

# Summary output
resource "local_file" "summary" {
  content  = <<-EOT
    CONVERT() FUNCTION DEMONSTRATION
    ================================
    
    This example demonstrates the convert() function introduced in Terraform 1.15.
    
    Key Features Demonstrated:
    1. Basic type conversions (string ↔ number ↔ bool)
    2. Object type conversions with explicit structure
    3. List and map conversions with element type changes
    4. Complex nested structure conversions
    5. API response parsing with type safety
    6. Configuration file processing
    7. Input validation with type constraints
    
    Benefits of convert():
    ✓ Explicit type constraints
    ✓ Type safety for external data
    ✓ Complex type support (objects, nested structures)
    ✓ Better error messages
    ✓ Validation capabilities
    
    Check the output/ directory for detailed results of each conversion type.
    
    Generated at: ${timestamp()}
  EOT
  filename = "${path.module}/output/00-summary.txt"
}