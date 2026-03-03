# TF-301/3-sensitive-values Test: sensitive variables and outputs
# Variables: app_name (default), db_password (sensitive, default), api_key (sensitive, default), db_host (default)
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: sensitive = true redacts values in plan/apply output.
# Note: sensitive values CAN be accessed in test assertions — tests run in a
# trusted context and can verify the actual content of files.

run "creates_app_config_with_sensitive_content" {
  command = apply

  assert {
    condition     = endswith(local_file.app_config.filename, "app.conf")
    error_message = "app_config should write to app.conf"
  }

  assert {
    condition     = strcontains(local_file.app_config.content, "app_name    = \"hashi-training\"")
    error_message = "app.conf should contain the default app_name"
  }

  assert {
    condition     = strcontains(local_file.app_config.content, "db_host     = \"db.internal.example.com\"")
    error_message = "app.conf should contain the default db_host"
  }

  assert {
    condition     = strcontains(local_file.app_config.content, "db_password = \"super-secret-password-123\"")
    error_message = "app.conf should contain the db_password (file content is not redacted)"
  }
}

run "creates_public_config_without_sensitive_values" {
  command = apply

  assert {
    condition     = endswith(local_file.public_config.filename, "public.conf")
    error_message = "public_config should write to public.conf"
  }

  assert {
    condition     = local_file.public_config.content == "app_name = hashi-training\ndb_host = db.internal.example.com"
    error_message = "public.conf should contain only non-sensitive values"
  }
}

run "validation_rejects_short_password" {
  command = plan

  variables {
    db_password = "tooshort"
  }

  expect_failures = [var.db_password]
}

run "validation_rejects_short_api_key" {
  command = plan

  variables {
    api_key = "short"
  }

  expect_failures = [var.api_key]
}

run "custom_values_are_written_to_files" {
  command = apply

  variables {
    app_name    = "my-custom-app"
    db_host     = "custom-db.example.com"
    db_password = "my-secure-password-xyz"
    api_key     = "custom-api-key-abcdefghijklmnop"
  }

  assert {
    condition     = strcontains(local_file.app_config.content, "app_name    = \"my-custom-app\"")
    error_message = "app.conf should reflect custom app_name"
  }

  assert {
    condition     = strcontains(local_file.public_config.content, "app_name = my-custom-app")
    error_message = "public.conf should reflect custom app_name"
  }
}