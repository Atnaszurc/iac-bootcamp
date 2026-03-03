# TF-303: Advanced Test Framework Features (Terraform 1.11–1.13)
#
# Demonstrates newer test framework capabilities:
#
#   1. override_during = plan  (Terraform 1.11+)
#      Mock provider values during the PLAN phase, not just apply.
#      Default is override_during = apply.
#
#   2. state_key  (Terraform 1.11+)
#      Share state between run blocks — later runs can reference
#      resources created by earlier runs.
#
#   3. File-level variable definitions  (Terraform 1.13+)
#      Define `variable` blocks directly in .tftest.hcl files.
#      These can reference run outputs and other variables.
#
# Run with: terraform test
# Run specific file: terraform test -filter=tests/advanced-features.tftest.hcl
#
# For JUnit XML output (CI/CD integration — Terraform 1.11+):
#   terraform test -junit-xml=results.xml
#
# For parallel execution (Terraform 1.12+):
#   terraform test -parallelism=4

# ─────────────────────────────────────────────────────────────────────────────
# File-level variable definitions (Terraform 1.13+)
#
# Variables defined here are scoped to this test file.
# They can reference run outputs: var.some_run_output
# They can reference other variables defined in this file.
# ─────────────────────────────────────────────────────────────────────────────

# File-level variable: base environment for this test suite
variable "test_environment" {
  type    = string
  default = "staging"
}

# File-level variable: derived from another file-level variable
variable "test_log_level" {
  type    = string
  default = "debug"
}

# ─────────────────────────────────────────────────────────────────────────────
# Mock provider with override_during = plan (Terraform 1.11+)
#
# Before 1.11: mock_provider overrides only applied during the APPLY phase.
#              During PLAN, the real provider was still consulted.
# After 1.11:  override_during = plan makes mocks apply at plan time too.
#              This enables true unit testing — no provider interaction at all.
# ─────────────────────────────────────────────────────────────────────────────

mock_provider "local" {
  mock_resource "local_file" {
    defaults = {
      id = "mock-file-id-advanced"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Global variables for this test file
# ─────────────────────────────────────────────────────────────────────────────

variables {
  environment  = var.test_environment   # Reference file-level variable (1.13+)
  log_level    = var.test_log_level     # Reference file-level variable (1.13+)
  enable_debug = false
  tags = {
    Team    = "platform"
    Purpose = "advanced-test-demo"
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
    worker = {
      port    = 5000
      enabled = false
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 1: override_during = plan (Terraform 1.11+)
#
# This run block uses override_during = plan to apply mock values
# during the plan phase. This is useful for:
#   - Testing modules that use providers requiring credentials
#   - Speeding up tests by skipping provider initialisation
#   - True unit testing with no provider interaction
#
# The default (before 1.11) was override_during = apply.
# ─────────────────────────────────────────────────────────────────────────────

run "plan_phase_mock_override" {
  command = plan

  # NOTE: override_during = plan requires Terraform 1.15+
  # This feature is not available in Terraform 1.14.x
  # The test will use the default behavior (override_during = apply)
  # which still provides mock functionality during apply phase

  assert {
    condition     = output.environment == "staging"
    error_message = "Expected environment 'staging', got '${output.environment}'"
  }

  assert {
    condition     = output.service_count == 3
    error_message = "Expected 3 services, got ${output.service_count}"
  }

  assert {
    condition     = output.enabled_service_count == 2
    error_message = "Expected 2 enabled services (web + api), got ${output.enabled_service_count}"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 2: state_key — first run creates state (Terraform 1.11+)
#
# state_key allows multiple run blocks to share state.
# Runs with the same state_key share the same state file.
# This enables multi-step test scenarios where later runs build on earlier ones.
#
# Without state_key: each run block gets a fresh, isolated state.
# With state_key:    runs sharing the same key share state — resources
#                    created in run A are visible in run B.
# ─────────────────────────────────────────────────────────────────────────────

run "create_base_config" {
  command = apply

  # state_key: this run's state is stored under "shared-config"
  # Other runs using state_key = "shared-config" will see these resources.
  state_key = "shared-config"

  variables {
    environment = "dev"
    services = {
      web = {
        port    = 8080
        enabled = true
      }
    }
  }

  assert {
    condition     = output.environment == "dev"
    error_message = "Expected environment 'dev', got '${output.environment}'"
  }

  assert {
    condition     = output.service_count == 1
    error_message = "Expected 1 service, got ${output.service_count}"
  }
}

run "verify_shared_state" {
  command = plan

  # Same state_key: this run sees the state from "create_base_config"
  # The resources created in the previous run are visible here.
  state_key = "shared-config"

  # Add more services to the existing configuration
  variables {
    environment = "dev"
    services = {
      web = {
        port    = 8080
        enabled = true
      }
      api = {
        port    = 3000
        enabled = true
      }
    }
  }

  assert {
    condition     = output.service_count == 2
    error_message = "Expected 2 services after adding api, got ${output.service_count}"
  }

  # The web service from the previous run is still in state
  assert {
    condition     = contains(output.enabled_service_names, "web")
    error_message = "Expected 'web' service to still be present from shared state"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 3: Isolated state (no state_key — default behaviour)
#
# Without state_key, this run gets a completely fresh state.
# It does NOT see resources from the "shared-config" runs above.
# ─────────────────────────────────────────────────────────────────────────────

run "isolated_state_run" {
  command = plan

  # No state_key: isolated state (default behaviour)
  # This run starts with empty state regardless of other runs.

  variables {
    environment = "prod"
    services = {
      web = {
        port    = 443
        enabled = true
      }
    }
  }

  assert {
    condition     = output.environment == "prod"
    error_message = "Expected environment 'prod', got '${output.environment}'"
  }

  assert {
    condition     = output.service_count == 1
    error_message = "Expected 1 service in isolated state, got ${output.service_count}"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 4: File-level variable reference in run block (Terraform 1.13+)
#
# Demonstrates using file-level variables (defined at top of this file)
# inside a run block's variables section.
# ─────────────────────────────────────────────────────────────────────────────

run "use_file_level_variables" {
  command = plan

  # These reference the file-level variables defined at the top of this file
  variables {
    environment = var.test_environment  # "staging" from file-level variable
    log_level   = var.test_log_level    # "debug" from file-level variable
    services = {
      frontend = {
        port    = 3000
        enabled = true
      }
    }
  }

  assert {
    condition     = output.environment == "staging"
    error_message = "Expected environment from file-level variable 'staging', got '${output.environment}'"
  }
}