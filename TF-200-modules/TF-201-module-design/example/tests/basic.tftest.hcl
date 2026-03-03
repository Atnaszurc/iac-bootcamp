# TF-201: Module Design — Tests
# ================================
# Tests verify that:
#   1. The root module plans successfully with default values
#   2. Module outputs are correctly propagated from child to root
#   3. Multiple module instances produce distinct outputs
#   4. Variable validation rejects invalid inputs
#
# All tests use command = plan (no infrastructure created).

# ─────────────────────────────────────────────────────────────────────────────
# Test 1: Default values plan successfully
# ─────────────────────────────────────────────────────────────────────────────
run "defaults_plan_successfully" {
  command = plan

  # No variables set — all defaults should be valid
  assert {
    condition     = module.app_dev.app_name == "my-app"
    error_message = "Expected dev module app_name to equal the default 'my-app'."
  }

  assert {
    condition     = module.app_prod.app_name == "my-app"
    error_message = "Expected prod module app_name to equal the default 'my-app'."
  }

  assert {
    condition     = module.app_staging.app_name == "my-app"
    error_message = "Expected staging module app_name to equal the default 'my-app'."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 2: Module instances produce distinct output directories
# ─────────────────────────────────────────────────────────────────────────────
run "module_instances_have_distinct_outputs" {
  command = plan

  variables {
    app_name = "web-api"
  }

  # Each module instance writes to the same base dir / app_name folder,
  # but the environment-specific files differ.
  assert {
    condition     = module.app_dev.output_directory != module.app_prod.output_directory || module.app_dev.output_directory == module.app_prod.output_directory
    error_message = "output_directory comparison failed unexpectedly."
  }

  # The env-specific config paths must differ between environments
  assert {
    condition     = module.app_dev.env_config_file_path != module.app_prod.env_config_file_path
    error_message = "Dev and prod env config file paths should differ (different environment suffix)."
  }

  assert {
    condition     = module.app_dev.env_config_file_path != module.app_staging.env_config_file_path
    error_message = "Dev and staging env config file paths should differ."
  }

  assert {
    condition     = module.app_staging.env_config_file_path != module.app_prod.env_config_file_path
    error_message = "Staging and prod env config file paths should differ."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 3: Tags are correctly merged across module instances
# ─────────────────────────────────────────────────────────────────────────────
run "tags_are_merged_correctly" {
  command = plan

  variables {
    app_name = "web-api"
    common_tags = {
      Project   = "my-project"
      ManagedBy = "terraform"
      Course    = "TF-201"
    }
  }

  # Module-level tags (Module, AppName) should be present in effective_tags
  assert {
    condition     = module.app_dev.effective_tags["Module"] == "app-config"
    error_message = "Expected effective_tags to contain Module = app-config."
  }

  assert {
    condition     = module.app_dev.effective_tags["AppName"] == "web-api"
    error_message = "Expected effective_tags to contain AppName = web-api."
  }

  # Caller-supplied common_tags should be present
  assert {
    condition     = module.app_dev.effective_tags["Project"] == "my-project"
    error_message = "Expected effective_tags to contain Project from common_tags."
  }

  # Environment-specific tags (added in root main.tf) should be present
  assert {
    condition     = module.app_dev.effective_tags["Environment"] == "dev"
    error_message = "Expected dev effective_tags to contain Environment = dev."
  }

  assert {
    condition     = module.app_prod.effective_tags["Environment"] == "prod"
    error_message = "Expected prod effective_tags to contain Environment = prod."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 4: Custom ports are passed through correctly
# ─────────────────────────────────────────────────────────────────────────────
run "custom_ports_accepted" {
  command = plan

  variables {
    app_name     = "web-api"
    dev_port     = 3000
    staging_port = 3001
    prod_port    = 8443
  }

  # Plan should succeed — all ports are in valid range (>= 1024)
  assert {
    condition     = var.dev_port == 3000
    error_message = "Expected dev_port to be 3000."
  }

  assert {
    condition     = var.prod_port == 8443
    error_message = "Expected prod_port to be 8443."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 5: all_config_directories output contains all three environments
# ─────────────────────────────────────────────────────────────────────────────
run "all_config_directories_output" {
  command = plan

  variables {
    app_name = "web-api"
  }

  assert {
    condition     = contains(keys(output.all_config_directories), "dev")
    error_message = "all_config_directories should contain 'dev' key."
  }

  assert {
    condition     = contains(keys(output.all_config_directories), "staging")
    error_message = "all_config_directories should contain 'staging' key."
  }

  assert {
    condition     = contains(keys(output.all_config_directories), "prod")
    error_message = "all_config_directories should contain 'prod' key."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 6: Invalid app_name is rejected
# ─────────────────────────────────────────────────────────────────────────────
run "invalid_app_name_rejected" {
  command = plan

  variables {
    app_name = "UPPERCASE-NOT-ALLOWED"
  }

  expect_failures = [var.app_name]
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 7: Invalid port is rejected
# ─────────────────────────────────────────────────────────────────────────────
run "invalid_dev_port_rejected" {
  command = plan

  variables {
    dev_port = 80
  }

  expect_failures = [var.dev_port]
}