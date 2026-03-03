# TF-302/3-lifecycle-arguments Test: lifecycle meta-arguments
# Variables: app_name (default), config_version (default "v1"), environment (default "dev")
# Provider: hashicorp/local + terraform_data (no credentials required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: create_before_destroy, prevent_destroy, ignore_changes,
# replace_triggered_by, postcondition.

run "creates_all_three_config_files" {
  command = apply

  assert {
    condition     = endswith(local_file.app_config.filename, "app.conf")
    error_message = "app_config should write to app.conf"
  }

  assert {
    condition     = endswith(local_file.critical_config.filename, "critical.conf")
    error_message = "critical_config should write to critical.conf"
  }

  assert {
    condition     = endswith(local_file.operator_config.filename, "operator.conf")
    error_message = "operator_config should write to operator.conf"
  }
}

run "app_config_content_reflects_variables" {
  command = apply

  assert {
    condition     = strcontains(local_file.app_config.content, "app     = hashi-training")
    error_message = "app.conf should contain default app_name"
  }

  assert {
    condition     = strcontains(local_file.app_config.content, "version = v1")
    error_message = "app.conf should contain default config_version v1"
  }

  assert {
    condition     = strcontains(local_file.app_config.content, "env     = dev")
    error_message = "app.conf should contain default environment dev"
  }
}

run "config_version_validation_rejects_invalid_format" {
  command = plan

  variables {
    config_version = "version-1"
  }

  expect_failures = [var.config_version]
}

run "environment_validation_rejects_invalid_value" {
  command = plan

  variables {
    environment = "test"
  }

  expect_failures = [var.environment]
}

run "custom_variables_are_reflected_in_configs" {
  command = apply

  variables {
    app_name       = "my-app"
    config_version = "v2"
    environment    = "staging"
  }

  assert {
    condition     = strcontains(local_file.app_config.content, "app     = my-app")
    error_message = "app.conf should reflect custom app_name"
  }

  assert {
    condition     = strcontains(local_file.app_config.content, "version = v2")
    error_message = "app.conf should reflect config_version v2"
  }

  assert {
    condition     = strcontains(local_file.app_config.content, "env     = staging")
    error_message = "app.conf should reflect staging environment"
  }

  assert {
    condition     = strcontains(local_file.critical_config.content, "app = my-app")
    error_message = "critical.conf should reflect custom app_name"
  }

  assert {
    condition     = strcontains(local_file.critical_config.content, "env = staging")
    error_message = "critical.conf should reflect staging environment"
  }
}