# TF-303: Terraform Test Framework — Integration Tests
#
# Demonstrates advanced test framework patterns:
#   - Sequential runs that build on each other
#   - expect_failures — testing that validation REJECTS bad input
#   - Testing multiple environments in one file
#   - Testing edge cases and boundary conditions
#   - Descriptive run names that document intent
#
# Run with: terraform test
# All tests use command = plan — no real files are created.

# ─────────────────────────────────────────────────────────────────────────────
# Global variables — minimal defaults, overridden per run
# ─────────────────────────────────────────────────────────────────────────────

variables {
  environment  = "dev"
  log_level    = "info"
  enable_debug = false
  tags         = {}
  services = {
    app = {
      port    = 8080
      enabled = true
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 1: Validate that invalid environment is rejected
#
# expect_failures tests that Terraform REJECTS bad input.
# This is how you test your validation blocks work correctly.
# ─────────────────────────────────────────────────────────────────────────────

run "invalid_environment_is_rejected" {
  command = plan

  variables {
    environment = "production" # not in allowed list: dev, staging, prod
  }

  expect_failures = [
    var.environment,
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 2: Validate that invalid log level is rejected
# ─────────────────────────────────────────────────────────────────────────────

run "invalid_log_level_is_rejected" {
  command = plan

  variables {
    log_level = "verbose" # not in allowed list: debug, info, warn, error
  }

  expect_failures = [
    var.log_level,
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 3: Validate that invalid port is rejected
# ─────────────────────────────────────────────────────────────────────────────

run "invalid_port_is_rejected" {
  command = plan

  variables {
    services = {
      bad_service = {
        port    = 99999 # > 65535, invalid
        enabled = true
      }
    }
  }

  expect_failures = [
    var.services,
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 4: Validate that empty services map is rejected
# ─────────────────────────────────────────────────────────────────────────────

run "empty_services_map_is_rejected" {
  command = plan

  variables {
    services = {}
  }

  expect_failures = [
    var.services,
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 5: Valid boundary values are accepted
#
# Port 1 and port 65535 are the valid extremes.
# ─────────────────────────────────────────────────────────────────────────────

run "boundary_ports_are_valid" {
  command = plan

  variables {
    services = {
      low_port = {
        port    = 1
        enabled = true
      }
      high_port = {
        port    = 65535
        enabled = true
      }
    }
  }

  assert {
    condition     = output.service_count == 2
    error_message = "Expected 2 services with boundary ports, got ${output.service_count}"
  }

  assert {
    condition     = output.enabled_service_count == 2
    error_message = "Expected both boundary-port services to be enabled"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 6: Dev environment — full configuration test
# ─────────────────────────────────────────────────────────────────────────────

run "dev_environment_full_config" {
  command = plan

  variables {
    environment  = "dev"
    log_level    = "debug"
    enable_debug = true
    tags = {
      Team      = "backend"
      CostCentre = "engineering"
    }
    services = {
      web     = { port = 80,   enabled = true  }
      api     = { port = 8080, enabled = true  }
      worker  = { port = 5000, enabled = true  }
      monitor = { port = 9090, enabled = false }
    }
  }

  assert {
    condition     = output.environment == "dev"
    error_message = "Expected environment 'dev'"
  }

  assert {
    condition     = output.service_count == 4
    error_message = "Expected 4 services, got ${output.service_count}"
  }

  assert {
    condition     = output.enabled_service_count == 3
    error_message = "Expected 3 enabled services (web, api, worker), got ${output.enabled_service_count}"
  }

  assert {
    condition     = output.debug_enabled == true
    error_message = "Expected debug to be enabled in dev"
  }

  assert {
    condition     = output.common_tags["Team"] == "backend"
    error_message = "Expected Team tag 'backend'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 7: Staging environment — no debug, warn log level
# ─────────────────────────────────────────────────────────────────────────────

run "staging_environment_config" {
  command = plan

  variables {
    environment  = "staging"
    log_level    = "warn"
    enable_debug = false
    services = {
      web = { port = 80,   enabled = true }
      api = { port = 8080, enabled = true }
    }
  }

  assert {
    condition     = output.environment == "staging"
    error_message = "Expected environment 'staging'"
  }

  assert {
    condition     = output.debug_enabled == false
    error_message = "Expected debug disabled in staging"
  }

  assert {
    condition     = output.debug_file_path == null
    error_message = "Expected no debug file in staging"
  }

  assert {
    condition     = can(regex("/staging/", output.summary_file_path))
    error_message = "Expected summary file path to contain '/staging/', got: ${output.summary_file_path}"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 8: Prod environment — error log level, no debug
# ─────────────────────────────────────────────────────────────────────────────

run "prod_environment_config" {
  command = plan

  variables {
    environment  = "prod"
    log_level    = "error"
    enable_debug = false
    tags = {
      CostCentre = "production"
      Criticality = "high"
    }
    services = {
      web = { port = 443,  enabled = true }
      api = { port = 8443, enabled = true }
    }
  }

  assert {
    condition     = output.environment == "prod"
    error_message = "Expected environment 'prod'"
  }

  assert {
    condition     = output.common_tags["Environment"] == "prod"
    error_message = "Expected Environment tag 'prod'"
  }

  assert {
    condition     = output.common_tags["Criticality"] == "high"
    error_message = "Expected Criticality tag 'high'"
  }

  assert {
    condition     = output.debug_enabled == false
    error_message = "Expected debug disabled in prod"
  }

  assert {
    condition     = can(regex("/prod/web\\.conf$", output.config_file_paths["web"]))
    error_message = "Expected prod web config at '/prod/web.conf', got: ${output.config_file_paths["web"]}"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 9: Environment case-insensitivity
#
# Tests that "PROD", "Prod", and "prod" all normalise to "prod".
# ─────────────────────────────────────────────────────────────────────────────

run "environment_case_insensitive_PROD" {
  command = plan

  variables {
    environment = "PROD"
  }

  assert {
    condition     = output.environment == "prod"
    error_message = "Expected 'PROD' to normalise to 'prod', got '${output.environment}'"
  }
}

run "environment_case_insensitive_Staging" {
  command = plan

  variables {
    environment = "Staging"
  }

  assert {
    condition     = output.environment == "staging"
    error_message = "Expected 'Staging' to normalise to 'staging', got '${output.environment}'"
  }
}