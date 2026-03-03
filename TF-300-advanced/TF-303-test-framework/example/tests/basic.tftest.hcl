# TF-303: Terraform Test Framework — Basic Tests
#
# Demonstrates the core Terraform test framework features:
#   - Global variables block
#   - Multiple run blocks
#   - command = plan (no infrastructure created)
#   - assert blocks with descriptive error messages
#   - Per-run variable overrides
#   - Testing conditional resources
#   - Testing computed locals and outputs
#
# Run with: terraform test
# All tests use command = plan — no real files are created.

# ─────────────────────────────────────────────────────────────────────────────
# Global variables — shared across all run blocks unless overridden
# ─────────────────────────────────────────────────────────────────────────────

variables {
  environment = "dev"
  log_level   = "info"
  enable_debug = false
  tags = {
    Team    = "platform"
    Project = "tf-303-demo"
  }
  services = {
    web = {
      port    = 8080
      enabled = true
    }
    api = {
      port    = 3000
      enabled = true
    }
    metrics = {
      port    = 9090
      enabled = false
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 1: Verify environment normalisation
#
# Tests that the `environment` local lowercases the input variable.
# ─────────────────────────────────────────────────────────────────────────────

run "environment_is_normalised_to_lowercase" {
  command = plan

  variables {
    environment = "DEV" # uppercase input
  }

  assert {
    condition     = output.environment == "dev"
    error_message = "Expected environment output to be 'dev' (lowercase), got '${output.environment}'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 2: Verify service counts
#
# Tests that the module correctly counts total vs enabled services.
# ─────────────────────────────────────────────────────────────────────────────

run "service_counts_are_correct" {
  command = plan

  assert {
    condition     = output.service_count == 3
    error_message = "Expected 3 total services, got ${output.service_count}"
  }

  assert {
    condition     = output.enabled_service_count == 2
    error_message = "Expected 2 enabled services (web + api), got ${output.enabled_service_count}"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 3: Verify enabled service names
#
# Tests that only enabled services appear in the output list.
# ─────────────────────────────────────────────────────────────────────────────

run "enabled_services_are_correct" {
  command = plan

  assert {
    condition     = contains(output.enabled_service_names, "web")
    error_message = "Expected 'web' in enabled services, got: ${jsonencode(output.enabled_service_names)}"
  }

  assert {
    condition     = contains(output.enabled_service_names, "api")
    error_message = "Expected 'api' in enabled services, got: ${jsonencode(output.enabled_service_names)}"
  }

  assert {
    condition     = !contains(output.enabled_service_names, "metrics")
    error_message = "Expected 'metrics' to be excluded (disabled), got: ${jsonencode(output.enabled_service_names)}"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 4: Verify config file paths include environment name
#
# Tests that file paths are constructed correctly using the environment.
# ─────────────────────────────────────────────────────────────────────────────

run "config_file_paths_contain_environment" {
  command = plan

  assert {
    condition     = can(regex("/dev/web\\.conf$", output.config_file_paths["web"]))
    error_message = "Expected web config path to contain '/dev/web.conf', got: ${output.config_file_paths["web"]}"
  }

  assert {
    condition     = can(regex("/dev/api\\.conf$", output.config_file_paths["api"]))
    error_message = "Expected api config path to contain '/dev/api.conf', got: ${output.config_file_paths["api"]}"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 5: Verify debug resource is NOT created when disabled
#
# Tests the conditional resource (count = 0 when enable_debug = false).
# ─────────────────────────────────────────────────────────────────────────────

run "debug_file_not_created_when_disabled" {
  command = plan

  # enable_debug = false (from global variables)

  assert {
    condition     = output.debug_enabled == false
    error_message = "Expected debug_enabled to be false"
  }

  assert {
    condition     = output.debug_file_path == null
    error_message = "Expected debug_file_path to be null when debug is disabled"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 6: Verify debug resource IS created when enabled
#
# Overrides enable_debug to true for this run only.
# ─────────────────────────────────────────────────────────────────────────────

run "debug_file_created_when_enabled" {
  command = plan

  variables {
    enable_debug = true
  }

  assert {
    condition     = output.debug_enabled == true
    error_message = "Expected debug_enabled to be true"
  }

  assert {
    condition     = output.debug_file_path != null
    error_message = "Expected debug_file_path to be set when debug is enabled"
  }

  assert {
    condition     = can(regex("/dev/debug\\.txt$", output.debug_file_path))
    error_message = "Expected debug file path to end with '/dev/debug.txt', got: ${tostring(output.debug_file_path)}"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 7: Verify common tags include required keys
#
# Tests that the module merges user tags with required system tags.
# ─────────────────────────────────────────────────────────────────────────────

run "common_tags_include_required_keys" {
  command = plan

  assert {
    condition     = output.common_tags["Environment"] == "dev"
    error_message = "Expected Environment tag to be 'dev', got: ${output.common_tags["Environment"]}"
  }

  assert {
    condition     = output.common_tags["ManagedBy"] == "terraform"
    error_message = "Expected ManagedBy tag to be 'terraform', got: ${tostring(lookup(output.common_tags, "ManagedBy", "missing"))}"
  }

  assert {
    condition     = output.common_tags["Team"] == "platform"
    error_message = "Expected user-supplied Team tag to be preserved, got: ${tostring(lookup(output.common_tags, "Team", "missing"))}"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 8: Verify prod environment configuration
#
# Tests the same module with production settings.
# ─────────────────────────────────────────────────────────────────────────────

run "prod_environment_configuration" {
  command = plan

  variables {
    environment  = "prod"
    log_level    = "warn"
    enable_debug = false
    services = {
      web = {
        port    = 443
        enabled = true
      }
      api = {
        port    = 8443
        enabled = true
      }
    }
  }

  assert {
    condition     = output.environment == "prod"
    error_message = "Expected environment to be 'prod', got: ${output.environment}"
  }

  assert {
    condition     = output.service_count == 2
    error_message = "Expected 2 services in prod, got: ${output.service_count}"
  }

  assert {
    condition     = output.enabled_service_count == 2
    error_message = "Expected all 2 prod services to be enabled, got: ${output.enabled_service_count}"
  }

  assert {
    condition     = can(regex("/prod/web\\.conf$", output.config_file_paths["web"]))
    error_message = "Expected prod web config path to contain '/prod/web.conf', got: ${output.config_file_paths["web"]}"
  }
}