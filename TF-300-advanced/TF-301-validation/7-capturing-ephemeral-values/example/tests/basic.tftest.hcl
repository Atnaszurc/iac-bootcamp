# TF-301 Section 7: Capturing Ephemeral Values — Test Suite
#
# Uses command = apply: the ephemeral password only exists during apply, so
# the captured value is unknown at plan time.
# Runs share state in order, which lets later runs compare with earlier ones.
#
# Key behaviors verified:
# - The store block captures a password of the requested length
# - Re-applying with the same version keeps the same password
# - Bumping the version rotates it

run "capture_initial_password" {
  command = apply

  assert {
    condition     = length(terraform_data.db_password.store.sensitive_output) == 24
    error_message = "Captured password should have the default length of 24"
  }

  assert {
    condition     = terraform_data.db_password.store.input == null
    error_message = "store.input is write-only and must never be persisted"
  }

  assert {
    condition     = output.password_version == 1
    error_message = "Initial password version should be 1"
  }
}

run "same_version_keeps_password" {
  command = apply

  assert {
    condition     = output.password_fingerprint == run.capture_initial_password.password_fingerprint
    error_message = "Re-applying with the same version must not change the captured password"
  }
}

run "bump_version_rotates_password" {
  command = apply

  variables {
    password_version = 2
  }

  assert {
    condition     = output.password_fingerprint != run.capture_initial_password.password_fingerprint
    error_message = "Bumping password_version should capture a new password"
  }

  assert {
    condition     = output.password_version == 2
    error_message = "password_version output should reflect the bump"
  }
}

run "reject_short_password" {
  command = plan

  variables {
    password_length = 8
  }

  expect_failures = [var.password_length]
}
