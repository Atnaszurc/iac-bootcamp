# TF-302 Section 4: Write-Only Attributes — Test Suite
#
# Tests the write-only attributes pattern using command = plan.
# The ephemeral db_password must be supplied via variables blocks.
#
# Key behaviors verified:
# - Plan succeeds with a valid ephemeral password
# - Regular outputs (db_name, db_host, environment, password_version) are correct
# - Password version tracking works correctly
# - Validation rules on db_password (length >= 12) and db_password_version (>= 1) work
#
# Note: The ephemeral db_password is never visible in outputs or state.
# The test verifies the plan succeeds and non-secret outputs are correct.

# ─────────────────────────────────────────────────────────────────────────────
# Run 1: Basic plan — default values with valid password
# Verifies: plan succeeds, all default outputs are correct
# ─────────────────────────────────────────────────────────────────────────────

run "basic_write_only_pattern" {
  command = plan

  variables {
    db_password = "SuperSecret123!"  # ephemeral — satisfies length >= 12
    # All other variables use defaults:
    # db_name             = "appdb"
    # db_host             = "db.example.internal"
    # environment         = "dev"
    # db_password_version = 1
  }

  assert {
    condition     = output.db_name == "appdb"
    error_message = "db_name should use default value 'appdb'"
  }

  assert {
    condition     = output.db_host == "db.example.internal"
    error_message = "db_host should use default value 'db.example.internal'"
  }

  assert {
    condition     = output.environment == "dev"
    error_message = "environment should use default value 'dev'"
  }

  assert {
    condition     = output.password_version == 1
    error_message = "password_version should use default value 1"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 2: Custom database configuration
# Verifies: custom values are reflected in outputs
# ─────────────────────────────────────────────────────────────────────────────

run "custom_database_config" {
  command = plan

  variables {
    db_password = "ProductionPass456!"
    db_name     = "production-db"
    db_host     = "prod-db.internal"
    environment = "prod"
  }

  assert {
    condition     = output.db_name == "production-db"
    error_message = "db_name should be 'production-db'"
  }

  assert {
    condition     = output.db_host == "prod-db.internal"
    error_message = "db_host should be 'prod-db.internal'"
  }

  assert {
    condition     = output.environment == "prod"
    error_message = "environment should be 'prod'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 3: Password rotation simulation
# Verifies: incrementing password_version is tracked in outputs
# This is the key mechanism for triggering password rotation
# ─────────────────────────────────────────────────────────────────────────────

run "password_rotation_version_2" {
  command = plan

  variables {
    db_password         = "RotatedPassword789!"
    db_password_version = 2  # Incremented to trigger rotation
    environment         = "staging"
  }

  assert {
    condition     = output.password_version == 2
    error_message = "password_version should be 2 after rotation"
  }

  assert {
    condition     = output.environment == "staging"
    error_message = "environment should be 'staging'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 4: Staging environment
# Verifies: staging environment is accepted by validation
# ─────────────────────────────────────────────────────────────────────────────

run "staging_environment" {
  command = plan

  variables {
    db_password = "StagingSecret321!"
    environment = "staging"
    db_name     = "staging-db"
  }

  assert {
    condition     = output.environment == "staging"
    error_message = "environment should be 'staging'"
  }

  assert {
    condition     = output.db_name == "staging-db"
    error_message = "db_name should be 'staging-db'"
  }
}