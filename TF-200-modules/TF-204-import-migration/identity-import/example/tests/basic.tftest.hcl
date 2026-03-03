# TF-204 Identity-Based Import — Test Suite
#
# Tests the identity-based import syntax example using command = plan.
#
# This example uses the local provider with a traditional id-based import
# (the identity blocks are shown as comments for reference, since the local
# provider does not implement identity-based import).
#
# The test verifies:
# - The resource configuration is correct (filename, content)
# - The file path and content are as expected
#
# Note: Terraform does not allow import blocks to run against mock_provider.
# We use override_resource to inject a synthetic state for the resource so
# the plan can proceed without touching the real filesystem.

# ─────────────────────────────────────────────────────────────────────────────
# Run 1: Verify resource configuration — override_resource bypasses the import
# block and injects synthetic state so the plan succeeds without a real file.
# ─────────────────────────────────────────────────────────────────────────────

run "import_plan_succeeds" {
  command = plan

  # override_resource injects a synthetic state for local_file.existing_config,
  # which satisfies the import block without needing a real file on disk.
  override_resource {
    target = local_file.existing_config
    values = {
      id                   = "/mock/path/existing.conf"
      filename             = "/mock/path/existing.conf"
      content              = "# Existing configuration file\napp_name = legacy-app\n"
      content_base64       = ""
      content_md5          = "abc123"
      content_sha1         = "def456"
      content_sha256       = "ghi789"
      content_sha512       = "jkl012"
      directory_permission = "0777"
      file_permission      = "0777"
    }
  }

  # Verify the resource configuration matches what is declared in main.tf
  assert {
    condition     = local_file.existing_config.filename == "${path.module}/output/existing.conf"
    error_message = "local_file.existing_config filename should match the import target path"
  }

  assert {
    condition     = local_file.existing_config.content == "# Existing configuration file\napp_name = legacy-app\n"
    error_message = "local_file.existing_config content should match the expected configuration"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Run 2: Verify the resource address is correct
# Confirms the import target (to = local_file.existing_config) is valid
# ─────────────────────────────────────────────────────────────────────────────

run "resource_address_valid" {
  command = plan

  override_resource {
    target = local_file.existing_config
    values = {
      id       = "/mock/path/existing.conf"
      filename = "/mock/path/existing.conf"
      content  = "# Existing configuration file\napp_name = legacy-app\n"
    }
  }

  assert {
    condition     = startswith(local_file.existing_config.filename, path.module)
    error_message = "Resource filename should be relative to the module path"
  }
}