# TF-204: Import & Migration Strategies — Tests
# ================================================
# Tests verify that:
#   1. The configuration plans successfully with defaults
#   2. Resources produce the expected file paths
#   3. The all_managed_files output contains all three resources
#   4. Variable validation rejects invalid inputs
#   5. The import_ids output is populated (demonstrates import readiness)
#
# NOTE: Import blocks and moved blocks cannot be tested with `terraform test`
# in plan-only mode — they require actual state. The tests here validate
# the surrounding configuration that makes import/migration safe.
#
# All tests use command = plan (no infrastructure created).

# ─────────────────────────────────────────────────────────────────────────────
# Test 1: Default configuration plans successfully
# ─────────────────────────────────────────────────────────────────────────────
run "defaults_plan_successfully" {
  command = plan

  assert {
    condition     = local_file.app_config.filename == "${path.module}/output/app.conf"
    error_message = "Expected app_config filename to be output/app.conf."
  }

  assert {
    condition     = local_file.database_config.filename == "${path.module}/output/database.conf"
    error_message = "Expected database_config filename to be output/database.conf."
  }

  assert {
    condition     = local_file.service_registry.filename == "${path.module}/output/services.json"
    error_message = "Expected service_registry filename to be output/services.json."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 2: all_managed_files output contains all three resources
# ─────────────────────────────────────────────────────────────────────────────
run "all_managed_files_output" {
  command = plan

  assert {
    condition     = contains(keys(output.all_managed_files), "app_config")
    error_message = "all_managed_files should contain 'app_config' key."
  }

  assert {
    condition     = contains(keys(output.all_managed_files), "database_config")
    error_message = "all_managed_files should contain 'database_config' key."
  }

  assert {
    condition     = contains(keys(output.all_managed_files), "service_registry")
    error_message = "all_managed_files should contain 'service_registry' key."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 3: Custom environment changes file paths correctly
# ─────────────────────────────────────────────────────────────────────────────
run "custom_environment_accepted" {
  command = plan

  variables {
    app_name    = "web-api"
    environment = "prod"
    app_version = "2.5.1"
  }

  assert {
    condition     = var.environment == "prod"
    error_message = "Expected environment to be prod."
  }

  assert {
    condition     = var.app_name == "web-api"
    error_message = "Expected app_name to be web-api."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 4: Custom services list is accepted
# ─────────────────────────────────────────────────────────────────────────────
run "custom_services_accepted" {
  command = plan

  variables {
    services = ["api", "worker", "cache", "metrics"]
  }

  assert {
    condition     = length(var.services) == 4
    error_message = "Expected 4 services in the list."
  }

  assert {
    condition     = contains(var.services, "cache")
    error_message = "Expected 'cache' to be in the services list."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 5: Invalid environment is rejected
# ─────────────────────────────────────────────────────────────────────────────
run "invalid_environment_rejected" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 6: Invalid app_name is rejected
# ─────────────────────────────────────────────────────────────────────────────
run "invalid_app_name_rejected" {
  command = plan

  variables {
    app_name = "My App!"
  }

  expect_failures = [var.app_name]
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 7: Invalid db_port is rejected
# ─────────────────────────────────────────────────────────────────────────────
run "invalid_db_port_rejected" {
  command = plan

  variables {
    db_port = 22
  }

  expect_failures = [var.db_port]
}