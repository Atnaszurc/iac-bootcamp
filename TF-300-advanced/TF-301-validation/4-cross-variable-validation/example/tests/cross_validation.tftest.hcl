# Tests for cross-variable validation (Terraform 1.9+)
# These tests verify that validation rules correctly enforce cross-variable constraints.
#
# Run with: terraform test

# ─────────────────────────────────────────────────────────────────────────────
# PASSING TESTS — valid configurations
# ─────────────────────────────────────────────────────────────────────────────

run "dev_minimal_config" {
  # Dev environment: relaxed rules — 1 instance, 10 GB disk, no backups
  variables {
    environment           = "dev"
    instance_count        = 1
    disk_size_gb          = 10
    enable_backups        = false
    backup_retention_days = 0
  }

  assert {
    condition     = output.deployment_summary.environment == "dev"
    error_message = "Environment should be dev"
  }

  assert {
    condition     = output.deployment_summary.instance_count == 1
    error_message = "Instance count should be 1"
  }
}

run "staging_standard_config" {
  # Staging: 2 instances, 20 GB disk, backups enabled
  variables {
    environment           = "staging"
    instance_count        = 2
    disk_size_gb          = 20
    enable_backups        = true
    backup_retention_days = 14
  }

  assert {
    condition     = output.deployment_summary.environment == "staging"
    error_message = "Environment should be staging"
  }
}

run "prod_full_config" {
  # Production: 3 instances (minimum), 100 GB disk, 30-day backups
  variables {
    environment           = "prod"
    instance_count        = 3
    disk_size_gb          = 100
    enable_backups        = true
    backup_retention_days = 30
  }

  assert {
    condition     = output.deployment_summary.environment == "prod"
    error_message = "Environment should be prod"
  }

  assert {
    condition     = output.deployment_summary.instance_count == 3
    error_message = "Prod instance count should be 3"
  }
}

run "prod_high_availability" {
  # Production with more instances than minimum
  variables {
    environment           = "prod"
    instance_count        = 5
    disk_size_gb          = 200
    enable_backups        = true
    backup_retention_days = 90
  }

  assert {
    condition     = output.deployment_summary.instance_count == 5
    error_message = "Instance count should be 5"
  }
}

run "backups_disabled_no_retention" {
  # Backups disabled: retention of 0 is valid
  variables {
    environment           = "staging"
    instance_count        = 1
    disk_size_gb          = 20
    enable_backups        = false
    backup_retention_days = 0
  }

  assert {
    condition     = output.deployment_summary.backups == "Disabled"
    error_message = "Backups should show as Disabled"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# FAILING TESTS — verify that invalid configurations are rejected
# These use expect_failures to confirm validation catches bad inputs
# ─────────────────────────────────────────────────────────────────────────────

run "prod_too_few_instances_fails" {
  command = plan
  # Production with only 1 instance should fail validation
  variables {
    environment           = "prod"
    instance_count        = 1   # INVALID: prod requires >= 3
    disk_size_gb          = 100
    enable_backups        = true
    backup_retention_days = 30
  }

  expect_failures = [
    var.instance_count,
  ]
}

run "prod_disk_too_small_fails" {
  command = plan
  # Production with 20 GB disk should fail validation
  variables {
    environment           = "prod"
    instance_count        = 3
    disk_size_gb          = 20   # INVALID: prod requires >= 50 GB
    enable_backups        = true
    backup_retention_days = 30
  }

  expect_failures = [
    var.disk_size_gb,
  ]
}

run "backups_enabled_low_retention_fails" {
  command = plan
  # Backups enabled but retention only 3 days should fail
  variables {
    environment           = "dev"
    instance_count        = 1
    disk_size_gb          = 10
    enable_backups        = true
    backup_retention_days = 3   # INVALID: must be >= 7 when backups enabled
  }

  expect_failures = [
    var.backup_retention_days,
  ]
}

run "invalid_environment_fails" {
  command = plan
  # Unknown environment value should fail
  variables {
    environment    = "production"   # INVALID: must be dev, staging, or prod
    instance_count = 1
    disk_size_gb   = 10
  }

  expect_failures = [
    var.environment,
  ]
}