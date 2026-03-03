# Tests for TF-102 top-level example: for_each with local_file
# All tests use command = plan (local provider, no external dependencies)
# Note: var.environment has no default — must be provided in every run block

# ---------------------------------------------------------------
# Test 1: Default file_contents with required environment
# ---------------------------------------------------------------
run "default_file_contents" {
  command = plan

  variables {
    environment = "dev"
  }

  assert {
    condition     = length(local_file.example_map) == 3
    error_message = "Should create 3 files from the 3 default file_contents entries"
  }
}

# ---------------------------------------------------------------
# Test 2: Files are named with environment prefix
# ---------------------------------------------------------------
run "files_have_environment_prefix" {
  command = plan

  variables {
    environment = "staging"
  }

  assert {
    condition     = local_file.example_map["file1.txt"].filename == "${path.module}/staging_file1.txt"
    error_message = "file1.txt should be prefixed with the environment name 'staging'"
  }

  assert {
    condition     = local_file.example_map["file2.txt"].filename == "${path.module}/staging_file2.txt"
    error_message = "file2.txt should be prefixed with the environment name 'staging'"
  }

  assert {
    condition     = local_file.example_map["file3.txt"].filename == "${path.module}/staging_file3.txt"
    error_message = "file3.txt should be prefixed with the environment name 'staging'"
  }
}

# ---------------------------------------------------------------
# Test 3: File content matches the map values
# ---------------------------------------------------------------
run "file_content_matches_map_values" {
  command = plan

  variables {
    environment = "dev"
  }

  assert {
    condition     = local_file.example_map["file1.txt"].content == "This is the content of file 1"
    error_message = "file1.txt content should match the default map value"
  }

  assert {
    condition     = local_file.example_map["file2.txt"].content == "Here's the content for file 2"
    error_message = "file2.txt content should match the default map value"
  }
}

# ---------------------------------------------------------------
# Test 4: Custom file_contents map
# ---------------------------------------------------------------
run "custom_file_contents" {
  command = plan

  variables {
    environment = "prod"
    file_contents = {
      "config.txt"  = "production config"
      "secrets.txt" = "production secrets"
    }
  }

  assert {
    condition     = length(local_file.example_map) == 2
    error_message = "Should create exactly 2 files from the custom file_contents map"
  }

  assert {
    condition     = local_file.example_map["config.txt"].filename == "${path.module}/prod_config.txt"
    error_message = "config.txt should be prefixed with 'prod' environment"
  }

  assert {
    condition     = local_file.example_map["config.txt"].content == "production config"
    error_message = "config.txt content should match the custom map value"
  }
}

# ---------------------------------------------------------------
# Test 5: Different environments produce different filenames
# ---------------------------------------------------------------
run "environment_changes_filenames" {
  command = plan

  variables {
    environment = "test"
    file_contents = {
      "app.conf" = "test configuration"
    }
  }

  assert {
    condition     = local_file.example_map["app.conf"].filename == "${path.module}/test_app.conf"
    error_message = "Filename should use 'test' environment prefix"
  }

  assert {
    condition     = !can(regex("^${path.module}/dev_", local_file.example_map["app.conf"].filename))
    error_message = "Filename should NOT use 'dev' prefix when environment is 'test'"
  }
}