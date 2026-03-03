# Tests for TF-101 Section 4: null_resource vs terraform_data
# All tests use command = plan (no provisioners execute, no files written)

# ---------------------------------------------------------------
# Test 1: Default variable values produce valid plan
# ---------------------------------------------------------------
run "default_variables_plan" {
  command = plan

  assert {
    condition     = local_file.app_config.filename == "${path.module}/app.conf"
    error_message = "app_config filename should be app.conf in the module directory"
  }

  assert {
    condition     = local_file.app_config.content != ""
    error_message = "app_config content should not be empty"
  }
}

# ---------------------------------------------------------------
# Test 2: terraform_data deployment_info stores correct input
# ---------------------------------------------------------------
run "terraform_data_input_values" {
  command = plan

  variables {
    environment = "staging"
    app_version = "2.0.0"
  }

  assert {
    condition     = terraform_data.deployment_info.input.environment == "staging"
    error_message = "deployment_info input should store the environment variable"
  }

  assert {
    condition     = terraform_data.deployment_info.input.version == "2.0.0"
    error_message = "deployment_info input should store the app_version variable"
  }
}

# ---------------------------------------------------------------
# Test 3: terraform_data config_tracker triggers_replace reflects variables
# ---------------------------------------------------------------
run "config_tracker_triggers" {
  command = plan

  variables {
    environment = "prod"
    app_version = "3.1.0"
  }

  assert {
    condition     = terraform_data.config_tracker.triggers_replace.version == "3.1.0"
    error_message = "config_tracker triggers_replace.version should match app_version"
  }

  assert {
    condition     = terraform_data.config_tracker.triggers_replace.environment == "prod"
    error_message = "config_tracker triggers_replace.environment should match environment variable"
  }
}

# ---------------------------------------------------------------
# Test 4: null_resource legacy example triggers reflect app_version
# ---------------------------------------------------------------
run "null_resource_triggers" {
  command = plan

  variables {
    app_version = "1.5.0"
    environment = "dev"
  }

  assert {
    condition     = null_resource.legacy_example.triggers.config_version == "1.5.0"
    error_message = "null_resource triggers.config_version should match app_version"
  }
}

# ---------------------------------------------------------------
# Test 5: app_config content contains environment and version
# ---------------------------------------------------------------
run "app_config_content_contains_vars" {
  command = plan

  variables {
    environment = "staging"
    app_version = "4.2.1"
  }

  assert {
    condition     = can(regex("staging", local_file.app_config.content))
    error_message = "app_config content should contain the environment value"
  }

  assert {
    condition     = can(regex("4\\.2\\.1", local_file.app_config.content))
    error_message = "app_config content should contain the app_version value"
  }
}