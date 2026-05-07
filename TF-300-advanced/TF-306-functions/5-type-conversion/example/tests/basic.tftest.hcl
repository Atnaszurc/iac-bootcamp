# Test file for convert() function (Terraform 1.15+)

# Test 1: Basic type conversions
run "test_basic_conversions" {
  command = plan

  assert {
    condition     = local.port_number == 8080
    error_message = "Port should be converted to number 8080"
  }

  assert {
    condition     = local.count_string == "5"
    error_message = "Count should be converted to string '5'"
  }

  assert {
    condition     = local.enabled_bool == true
    error_message = "Enabled should be converted to bool true"
  }

  assert {
    condition     = length(local.tags_set) == 3
    error_message = "Set should have 3 unique items (duplicates removed)"
  }
}

# Test 2: Object type conversions
run "test_object_conversions" {
  command = plan

  assert {
    condition     = local.typed_config.port == 8080
    error_message = "Port should be number 8080, not string"
  }

  assert {
    condition     = local.typed_config.enabled == true
    error_message = "Enabled should be bool true, not string"
  }

  assert {
    condition     = local.typed_config.replicas == 3
    error_message = "Replicas should be number 3, not string"
  }

  assert {
    condition     = local.total_capacity == 300
    error_message = "Total capacity calculation should work (3 * 100)"
  }
}

# Test 3: List and map conversions
run "test_collection_conversions" {
  command = plan

  assert {
    condition     = local.number_ports[0] == 80
    error_message = "First port should be number 80"
  }

  assert {
    condition     = local.number_limits.cpu_cores == 4
    error_message = "CPU cores should be number 4"
  }

  assert {
    condition     = local.total_memory == 48
    error_message = "Total memory should be 16 * 3 = 48"
  }
}

# Test 4: Complex nested structures
run "test_complex_structures" {
  command = plan

  assert {
    condition     = local.typed_environments.prod.instance_count == 5
    error_message = "Prod instance count should be number 5"
  }

  assert {
    condition     = local.typed_environments.prod.enable_backup == true
    error_message = "Prod backup should be bool true"
  }

  assert {
    condition     = local.typed_environments.prod.ports[0] == 80
    error_message = "Prod first port should be number 80"
  }

  assert {
    condition     = local.prod_total_instances == 5
    error_message = "Prod total instances should be 5"
  }
}

# Test 5: API response parsing
run "test_api_response" {
  command = plan

  assert {
    condition     = local.server_info.cpu_count == 4
    error_message = "CPU count should be number 4"
  }

  assert {
    condition     = local.server_info.is_running == true
    error_message = "Is running should be bool true"
  }

  assert {
    condition     = length(local.server_info.tags) == 3
    error_message = "Tags set should have 3 unique items"
  }

  assert {
    condition     = local.uptime_days == 30
    error_message = "Uptime should be 720 / 24 = 30 days"
  }

  assert {
    condition     = local.is_production == true
    error_message = "Should detect production tag"
  }
}

# Test 6: Configuration file processing
run "test_config_processing" {
  command = plan

  assert {
    condition     = local.app_config.application.port == 8080
    error_message = "App port should be number 8080"
  }

  assert {
    condition     = local.app_config.application.debug == false
    error_message = "Debug should be bool false"
  }

  assert {
    condition     = local.app_config.database.port == 5432
    error_message = "DB port should be number 5432"
  }

  assert {
    condition     = local.app_config.database.ssl_enabled == true
    error_message = "SSL should be bool true"
  }

  assert {
    condition     = local.total_workers == 12
    error_message = "Total workers should be 4 * 3 = 12"
  }
}

# Test 7: User input validation
run "test_validation" {
  command = plan

  assert {
    condition     = local.validated_user.age == 30
    error_message = "Age should be number 30"
  }

  assert {
    condition     = local.validated_user.active == true
    error_message = "Active should be bool true"
  }

  assert {
    condition     = length(local.validated_user.roles) == 2
    error_message = "Roles set should have 2 unique items"
  }

  assert {
    condition     = local.is_admin == true
    error_message = "Should detect admin role"
  }

  assert {
    condition     = local.is_adult == true
    error_message = "Should detect adult (age >= 18)"
  }
}

# Test 8: Output files created
run "test_output_files" {
  command = apply

  assert {
    condition     = local_file.basic_conversions.filename != ""
    error_message = "Basic conversions file should be created"
  }

  assert {
    condition     = local_file.object_conversions.filename != ""
    error_message = "Object conversions file should be created"
  }

  assert {
    condition     = local_file.complex_structures.filename != ""
    error_message = "Complex structures file should be created"
  }

  assert {
    condition     = local_file.summary.filename != ""
    error_message = "Summary file should be created"
  }
}

# Test 9: Type safety - ensure calculations work
run "test_type_safety" {
  command = plan

  # These calculations only work if types are correct
  assert {
    condition     = local.total_capacity > 0
    error_message = "Should be able to multiply numbers"
  }

  assert {
    condition     = local.memory_per_cpu == 2
    error_message = "Should be able to divide numbers (8 / 4 = 2)"
  }

  assert {
    condition     = local.total_storage_mb == 102400
    error_message = "Should be able to multiply numbers (100 * 1024)"
  }
}

# Test 10: Set operations (only work with proper types)
run "test_set_operations" {
  command = plan

  assert {
    condition     = contains(local.tags_set, "web")
    error_message = "Set should contain 'web'"
  }

  assert {
    condition     = contains(local.server_info.tags, "production")
    error_message = "Server tags should contain 'production'"
  }

  assert {
    condition     = contains(local.validated_user.roles, "admin")
    error_message = "User roles should contain 'admin'"
  }
}