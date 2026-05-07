variables {
  app_name       = "test-app"
  app_version    = "1.0.0"
  environment    = "dev"
  port           = 8080
  enabled        = true
  instance_count = 2
  instance_type  = "t3.micro"
}

run "test_basic_string_output" {
  command = plan

  assert {
    condition     = output.application_name == "test-app"
    error_message = "Application name should be 'test-app'"
  }
}

run "test_basic_number_output" {
  command = plan

  assert {
    condition     = output.port_number == 8080
    error_message = "Port number should be 8080"
  }
}

run "test_basic_bool_output" {
  command = plan

  assert {
    condition     = output.is_enabled == true
    error_message = "Application should be enabled"
  }

  assert {
    condition     = output.is_production == false
    error_message = "Dev environment should not be production"
  }
}

run "test_list_outputs" {
  command = plan

  assert {
    condition     = length(output.allowed_ports) == 3
    error_message = "Should have 3 allowed ports"
  }

  assert {
    condition     = contains(output.allowed_ports, 8080)
    error_message = "Allowed ports should contain 8080"
  }

  assert {
    condition     = length(output.instance_ids) == 2
    error_message = "Should have 2 instance IDs"
  }
}

run "test_map_outputs" {
  command = plan

  assert {
    condition     = output.environment_tags["Environment"] == "dev"
    error_message = "Environment tag should be 'dev'"
  }

  assert {
    condition     = output.environment_tags["Application"] == "test-app"
    error_message = "Application tag should be 'test-app'"
  }

  assert {
    condition     = output.environment_tags["ManagedBy"] == "Terraform"
    error_message = "ManagedBy tag should be 'Terraform'"
  }
}

run "test_set_output" {
  command = plan

  assert {
    condition     = length(output.unique_ports) == 4
    error_message = "Should have 4 unique ports"
  }
}

run "test_simple_object_output" {
  command = plan

  assert {
    condition     = output.application_config.name == "test-app"
    error_message = "Config name should be 'test-app'"
  }

  assert {
    condition     = output.application_config.version == "1.0.0"
    error_message = "Config version should be '1.0.0'"
  }

  assert {
    condition     = output.application_config.port == 8080
    error_message = "Config port should be 8080"
  }

  assert {
    condition     = output.application_config.enabled == true
    error_message = "Config should be enabled"
  }
}

run "test_database_config_object" {
  command = apply

  assert {
    condition     = output.database_config.port == 5432
    error_message = "Database port should be 5432"
  }

  assert {
    condition     = output.database_config.ssl == true
    error_message = "Database SSL should be enabled"
  }

  assert {
    condition     = can(regex(".*-db\\.example\\.com$", output.database_config.endpoint))
    error_message = "Database endpoint should end with '-db.example.com'"
  }
}

run "test_list_of_objects" {
  command = plan

  assert {
    condition     = length(output.instances) == 2
    error_message = "Should have 2 instances"
  }

  assert {
    condition     = output.instances[0].state == "running"
    error_message = "First instance should be running"
  }

  assert {
    condition     = can(regex("^10\\.0\\.[0-9]+\\.10$", output.instances[0].ip_address))
    error_message = "Instance IP should match pattern"
  }
}

run "test_map_of_objects" {
  command = plan

  assert {
    condition     = length(keys(output.instances_by_id)) == 2
    error_message = "Should have 2 instances in map"
  }

  assert {
    condition     = length(keys(output.environment_config)) == 3
    error_message = "Should have 3 environment configs"
  }

  assert {
    condition     = output.environment_config.dev.port == 8080
    error_message = "Dev port should be 8080"
  }

  assert {
    condition     = output.environment_config.prod.port == 443
    error_message = "Prod port should be 443"
  }
}

run "test_nested_object_output" {
  command = plan

  assert {
    condition     = output.infrastructure.application.name == "test-app"
    error_message = "Infrastructure app name should be 'test-app'"
  }

  assert {
    condition     = output.infrastructure.network.vpc_id == "vpc-12345"
    error_message = "VPC ID should be 'vpc-12345'"
  }

  assert {
    condition     = length(output.infrastructure.network.subnets) == 2
    error_message = "Should have 2 subnets"
  }

  assert {
    condition     = output.infrastructure.compute.instance_count == 2
    error_message = "Should have 2 instances"
  }
}

run "test_network_config" {
  command = plan

  assert {
    condition     = output.network_config.vpc.id == "vpc-12345"
    error_message = "VPC ID should be 'vpc-12345'"
  }

  assert {
    condition     = output.network_config.vpc.cidr == "10.0.0.0/16"
    error_message = "VPC CIDR should be '10.0.0.0/16'"
  }

  assert {
    condition     = length(output.network_config.subnets) == 2
    error_message = "Should have 2 subnets"
  }
}

run "test_optional_attributes" {
  command = plan

  assert {
    condition     = output.server_config.hostname == "test-app.example.com"
    error_message = "Hostname should be 'test-app.example.com'"
  }

  assert {
    condition     = output.server_config.port == 8080
    error_message = "Port should be 8080"
  }

  assert {
    condition     = output.server_config.ssl == false
    error_message = "SSL should be false for dev"
  }
}

run "test_connection_info" {
  command = plan

  assert {
    condition     = output.connection_info.port == 443
    error_message = "Connection port should be 443"
  }

  assert {
    condition     = output.connection_info.protocol == "HTTPS"
    error_message = "Protocol should be HTTPS"
  }

  assert {
    condition     = can(regex("^https://.*", output.connection_info.url))
    error_message = "URL should start with https://"
  }
}

run "test_endpoints" {
  command = plan

  assert {
    condition     = length(keys(output.endpoints)) == 3
    error_message = "Should have 3 endpoints"
  }

  assert {
    condition     = output.endpoints.api.port == 443
    error_message = "API endpoint port should be 443"
  }

  assert {
    condition     = can(regex("/api$", output.endpoints.api.url))
    error_message = "API URL should end with /api"
  }
}

run "test_type_conversions" {
  command = plan

  assert {
    condition     = output.port_as_string == "8080"
    error_message = "Port as string should be '8080'"
  }

  assert {
    condition     = output.port_as_number == 8080
    error_message = "Port as number should be 8080"
  }

  assert {
    condition     = output.enabled_as_string == "true"
    error_message = "Enabled as string should be 'true'"
  }
}

run "test_tuple_outputs" {
  command = plan

  assert {
    condition     = length(output.version_tuple) == 3
    error_message = "Version tuple should have 3 elements"
  }

  assert {
    condition     = output.version_tuple[0] == "1"
    error_message = "Major version should be '1'"
  }

  assert {
    condition     = length(output.config_tuple) == 3
    error_message = "Config tuple should have 3 elements"
  }
}

run "test_deployment_info" {
  command = plan

  assert {
    condition     = output.deployment_info.metadata.name == "test-app"
    error_message = "Deployment name should be 'test-app'"
  }

  assert {
    condition     = output.deployment_info.metadata.environment == "dev"
    error_message = "Deployment environment should be 'dev'"
  }

  assert {
    condition     = output.deployment_info.infrastructure.compute.instance_count == 2
    error_message = "Should have 2 instances in deployment"
  }

  assert {
    condition     = length(keys(output.deployment_info.connectivity.endpoints)) == 3
    error_message = "Should have 3 connectivity endpoints"
  }
}

run "test_production_environment" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = output.is_production == true
    error_message = "Prod environment should be production"
  }

  assert {
    condition     = output.server_config.ssl == true
    error_message = "SSL should be true for prod"
  }

  assert {
    condition     = output.environment_config.prod.enabled == true
    error_message = "Prod environment should be enabled"
  }
}

run "test_staging_environment" {
  command = plan

  variables {
    environment = "staging"
  }

  assert {
    condition     = output.is_production == false
    error_message = "Staging environment should not be production"
  }

  assert {
    condition     = output.environment_tags["Environment"] == "staging"
    error_message = "Environment tag should be 'staging'"
  }
}

run "test_different_instance_count" {
  command = plan

  variables {
    instance_count = 5
  }

  assert {
    condition     = length(output.instances) == 5
    error_message = "Should have 5 instances"
  }

  assert {
    condition     = output.infrastructure.compute.instance_count == 5
    error_message = "Infrastructure should show 5 instances"
  }
}

run "test_different_port" {
  command = plan

  variables {
    port = 3000
  }

  assert {
    condition     = output.port_number == 3000
    error_message = "Port should be 3000"
  }

  assert {
    condition     = output.application_config.port == 3000
    error_message = "Config port should be 3000"
  }

  assert {
    condition     = contains(output.allowed_ports, 3000)
    error_message = "Allowed ports should contain 3000"
  }
}