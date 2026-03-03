# TF-104/1-cli Test: for_each with map variable and environment prefix
# Variables: file_contents (map, has default), file_extension (has default), environment (NO default)
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: CLI workflow - init, plan, apply, show, state list, destroy
# This test validates the infrastructure that students manage via CLI commands.

run "creates_files_with_default_contents" {
  command = apply

  variables {
    environment = "dev"
  }

  assert {
    condition     = length(local_file.example_map) == 3
    error_message = "Expected 3 files from default file_contents map"
  }

  assert {
    condition     = local_file.example_map["file1.txt"].content == "This is the content of file 1"
    error_message = "file1.txt content should match default value"
  }

  assert {
    condition     = local_file.example_map["file2.txt"].content == "Here's the content for file 2"
    error_message = "file2.txt content should match default value"
  }

  assert {
    condition     = local_file.example_map["file3.txt"].content == "File 3 content goes here"
    error_message = "file3.txt content should match default value"
  }

  assert {
    condition     = endswith(local_file.example_map["file1.txt"].filename, "dev_file1.txt")
    error_message = "filename should be prefixed with environment 'dev'"
  }
}

run "creates_files_with_custom_environment" {
  command = apply

  variables {
    environment = "staging"
    file_contents = {
      "config.txt" = "staging configuration"
      "secrets.txt" = "staging secrets placeholder"
    }
  }

  assert {
    condition     = length(local_file.example_map) == 2
    error_message = "Expected 2 files with custom file_contents"
  }

  assert {
    condition     = endswith(local_file.example_map["config.txt"].filename, "staging_config.txt")
    error_message = "filename should be prefixed with environment 'staging'"
  }

  assert {
    condition     = local_file.example_map["config.txt"].content == "staging configuration"
    error_message = "config.txt content should match provided value"
  }
}