# TF-101 Test: Hello World with local_file resources
# Tests that all three files are created with correct content
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)

run "creates_hello_file" {
  command = apply

  assert {
    condition     = local_file.hello.content == "Hello, Terraform! This is my first infrastructure as code."
    error_message = "hello.txt content does not match expected value"
  }

  assert {
    condition     = local_file.hello.filename == "${path.module}/hello.txt"
    error_message = "hello.txt filename path is incorrect"
  }
}

run "creates_info_file" {
  command = apply

  assert {
    condition     = local_file.info.filename == "${path.module}/info.txt"
    error_message = "info.txt filename path is incorrect"
  }
}

run "creates_config_file" {
  command = apply

  assert {
    condition     = local_file.config.filename == "${path.module}/app-config.txt"
    error_message = "app-config.txt filename path is incorrect"
  }
}

run "outputs_are_populated" {
  command = apply

  assert {
    condition     = length(output.all_files) == 3
    error_message = "Expected 3 files in all_files output, got ${length(output.all_files)}"
  }

  assert {
    condition     = output.hello_file_id != ""
    error_message = "hello_file_id output should not be empty"
  }

  assert {
    condition     = output.info_file_id != ""
    error_message = "info_file_id output should not be empty"
  }

  assert {
    condition     = output.config_file_id != ""
    error_message = "config_file_id output should not be empty"
  }
}