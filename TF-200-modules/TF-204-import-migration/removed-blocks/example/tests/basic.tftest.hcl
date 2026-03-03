# TF-204/removed-blocks Test: removed blocks (Terraform 1.7+)
# No input variables
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: 'removed' blocks remove resources from state without destroying them.
# This test validates STEP 2 state: permanent_config is managed, handoff_config is removed.
#
# Note: The 'removed' block references local_file.handoff_config which was never in state
# during this test run — Terraform handles this gracefully (no-op for the removed block).

run "permanent_config_is_managed" {
  command = apply

  assert {
    condition     = local_file.permanent_config.content == "# Always managed by Terraform\nenv = production"
    error_message = "permanent.conf should contain the expected production config content"
  }

  assert {
    condition     = endswith(local_file.permanent_config.filename, "permanent.conf")
    error_message = "permanent_config should write to permanent.conf"
  }
}

run "only_permanent_config_exists_in_state" {
  command = plan

  assert {
    condition     = local_file.permanent_config.content == "# Always managed by Terraform\nenv = production"
    error_message = "permanent_config should remain in state with correct content"
  }
}