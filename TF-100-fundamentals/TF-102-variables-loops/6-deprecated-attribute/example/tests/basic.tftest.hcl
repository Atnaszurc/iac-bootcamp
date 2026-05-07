# Test file for deprecated attribute feature (Terraform 1.15+)

# Test 1: Using new variables (no warnings expected)
run "test_new_variables" {
  command = plan

  variables {
    instance_type    = "t3.small"
    environment      = "staging"
    enable_monitoring = true
  }

  assert {
    condition     = local.effective_instance_type == "t3.small"
    error_message = "Instance type should be t3.small"
  }

  assert {
    condition     = local.effective_environment == "staging"
    error_message = "Environment should be staging"
  }

  assert {
    condition     = local.effective_monitoring == true
    error_message = "Monitoring should be enabled"
  }
}

# Test 2: Using deprecated variables (warnings expected)
run "test_deprecated_variables" {
  command = plan

  variables {
    old_instance_type = "t2.large"
    env               = "prod"
    monitoring        = true
  }

  # These should still work but generate warnings
  assert {
    condition     = local.effective_instance_type == "t2.large"
    error_message = "Should use deprecated variable value"
  }

  assert {
    condition     = local.effective_environment == "prod"
    error_message = "Should use deprecated variable value"
  }
}

# Test 3: Mixed usage (new takes precedence)
run "test_mixed_variables" {
  command = plan

  variables {
    instance_type     = "t3.medium"
    old_instance_type = "t2.micro"
    environment       = "production"
    env               = "dev"
  }

  # New variables should take precedence
  assert {
    condition     = local.effective_instance_type == "t3.medium"
    error_message = "New variable should take precedence"
  }

  assert {
    condition     = local.effective_environment == "production"
    error_message = "New variable should take precedence"
  }
}

# Test 4: Default values
run "test_defaults" {
  command = plan

  # No variables set, should use defaults
  assert {
    condition     = local.effective_instance_type == "t3.micro"
    error_message = "Should use new default value"
  }

  assert {
    condition     = local.effective_environment == "development"
    error_message = "Should use new default value"
  }

  assert {
    condition     = local.effective_monitoring == false
    error_message = "Monitoring should be disabled by default"
  }
}

# Test 5: Verify outputs exist
run "test_outputs" {
  command = plan

  assert {
    condition     = output.instance_configuration != null
    error_message = "instance_configuration output should exist"
  }

  assert {
    condition     = output.migration_status != null
    error_message = "migration_status output should exist"
  }
}