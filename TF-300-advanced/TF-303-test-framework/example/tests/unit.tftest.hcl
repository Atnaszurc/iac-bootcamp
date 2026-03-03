# TF-303: Terraform Test Framework — Unit Tests with Mock Provider
#
# Demonstrates mock_provider (Terraform 1.7+) for unit testing.
#
# The `local` provider used in this module doesn't need mocking for plan-mode
# tests. This file shows the mock_provider PATTERN by overriding the local
# provider with a mock — useful when you want to:
#   - Intercept provider calls and return synthetic values
#   - Test configuration logic without any provider interaction
#   - Speed up tests by skipping provider initialisation
#   - Test modules that use providers requiring credentials
#
# In real projects you'd use mock_provider for AWS, Azure, GCP, etc.
# See: cloud-modules/*/example/tests/basic.tftest.hcl for cloud examples.
#
# Run with: terraform test
# All tests use command = plan with mock_provider.

# ─────────────────────────────────────────────────────────────────────────────
# Mock the `local` provider
#
# mock_provider intercepts all provider calls. For the local provider this
# means local_file resources return synthetic computed values instead of
# actually writing files.
# ─────────────────────────────────────────────────────────────────────────────

mock_provider "local" {
  # Override computed attributes that the provider would normally set.
  # This lets assertions on resource attributes work in plan mode.
  mock_resource "local_file" {
    defaults = {
      id = "mock-file-id"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Global variables
# ─────────────────────────────────────────────────────────────────────────────

variables {
  environment  = "staging"
  log_level    = "debug"
  enable_debug = true
  tags = {
    Owner = "unit-test"
  }
  services = {
    frontend = {
      port    = 80
      enabled = true
    }
    backend = {
      port    = 8080
      enabled = true
    }
    cache = {
      port    = 6379
      enabled = false
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 1: Verify mock provider intercepts resource creation
#
# With mock_provider, local_file resources are planned but not created.
# The mock returns synthetic values for computed attributes.
# ─────────────────────────────────────────────────────────────────────────────

run "mock_provider_intercepts_file_creation" {
  command = plan

  assert {
    condition     = output.environment == "staging"
    error_message = "Expected environment 'staging', got '${output.environment}'"
  }

  assert {
    condition     = output.service_count == 3
    error_message = "Expected 3 services, got ${output.service_count}"
  }

  # With mock_provider, the summary file is planned (not created)
  assert {
    condition     = local_file.summary.file_permission == "0644"
    error_message = "Expected summary file permission '0644', got '${local_file.summary.file_permission}'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 2: Test configuration logic — service filtering
#
# Verifies that the for_each filtering logic works correctly.
# This is pure configuration logic — no provider interaction needed.
# ─────────────────────────────────────────────────────────────────────────────

run "service_filtering_logic" {
  command = plan

  assert {
    condition     = output.enabled_service_count == 2
    error_message = "Expected 2 enabled services (frontend + backend), got ${output.enabled_service_count}"
  }

  assert {
    condition     = !contains(output.enabled_service_names, "cache")
    error_message = "Disabled service 'cache' should not appear in enabled_service_names"
  }

  # Verify for_each creates one file per service (including disabled)
  assert {
    condition     = length(output.config_file_paths) == 3
    error_message = "Expected config files for all 3 services, got ${length(output.config_file_paths)}"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 3: Test debug resource creation
#
# Verifies the conditional resource (count = 1 when enable_debug = true).
# ─────────────────────────────────────────────────────────────────────────────

run "debug_resource_created_with_mock" {
  command = plan

  # enable_debug = true (from global variables)

  assert {
    condition     = output.debug_enabled == true
    error_message = "Expected debug_enabled to be true"
  }

  assert {
    condition     = output.debug_file_path != null
    error_message = "Expected debug_file_path to be set when debug is enabled"
  }

  # Verify the debug file has restricted permissions
  assert {
    condition     = local_file.debug_info[0].file_permission == "0600"
    error_message = "Expected debug file to have restricted permissions '0600', got '${local_file.debug_info[0].file_permission}'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 4: Test tag merging logic
#
# Verifies that user tags are merged with system tags correctly.
# ─────────────────────────────────────────────────────────────────────────────

run "tag_merging_logic" {
  command = plan

  assert {
    condition     = output.common_tags["Environment"] == "staging"
    error_message = "Expected Environment tag 'staging', got '${output.common_tags["Environment"]}'"
  }

  assert {
    condition     = output.common_tags["ManagedBy"] == "terraform"
    error_message = "Expected ManagedBy tag 'terraform'"
  }

  assert {
    condition     = output.common_tags["Module"] == "TF-303-test-framework"
    error_message = "Expected Module tag 'TF-303-test-framework'"
  }

  assert {
    condition     = output.common_tags["Owner"] == "unit-test"
    error_message = "Expected user-supplied Owner tag to be preserved"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 5: Test with all services disabled
#
# Edge case: what happens when no services are enabled?
# ─────────────────────────────────────────────────────────────────────────────

run "all_services_disabled" {
  command = plan

  variables {
    services = {
      svc_a = {
        port    = 8080
        enabled = false
      }
      svc_b = {
        port    = 9090
        enabled = false
      }
    }
  }

  assert {
    condition     = output.service_count == 2
    error_message = "Expected 2 total services, got ${output.service_count}"
  }

  assert {
    condition     = output.enabled_service_count == 0
    error_message = "Expected 0 enabled services, got ${output.enabled_service_count}"
  }

  assert {
    condition     = length(output.enabled_service_names) == 0
    error_message = "Expected empty enabled_service_names list, got ${jsonencode(output.enabled_service_names)}"
  }
}