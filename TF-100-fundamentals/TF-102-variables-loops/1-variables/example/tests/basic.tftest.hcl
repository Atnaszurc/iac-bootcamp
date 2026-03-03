# TF-102/1-variables Test: Variable-driven local_file resources
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)

run "creates_files_with_defaults" {
  command = apply

  assert {
    condition     = local_file.example1.content == "Hello, Terraform!"
    error_message = "example1 content does not match expected value"
  }

  assert {
    condition     = local_file.example2.content == "This is another file created by Terraform."
    error_message = "example2 content does not match expected value"
  }
}

run "creates_files_with_custom_values" {
  command = apply

  variables {
    # Override defaults to test variable injection
  }

  assert {
    condition     = local_file.example1.filename != ""
    error_message = "example1 filename should not be empty"
  }

  assert {
    condition     = local_file.example2.filename != ""
    error_message = "example2 filename should not be empty"
  }
}