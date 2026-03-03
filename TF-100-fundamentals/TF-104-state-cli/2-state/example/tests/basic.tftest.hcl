# TF-104/2-state Test: for_each with map variable and environment prefix
# Variables: file_contents (map, has default), file_extension (has default), environment (NO default)
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: State management - terraform state list, show, mv, rm, pull, push
# This test validates the infrastructure whose state students inspect and manipulate.

run "creates_files_for_state_inspection" {
  command = apply

  variables {
    environment = "test"
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
    condition     = endswith(local_file.example_map["file1.txt"].filename, "test_file1.txt")
    error_message = "filename should be prefixed with environment 'test'"
  }
}

run "state_reflects_environment_change" {
  command = apply

  variables {
    environment = "prod"
    file_contents = {
      "app.txt"    = "Production application"
      "infra.txt"  = "Production infrastructure"
    }
  }

  assert {
    condition     = length(local_file.example_map) == 2
    error_message = "State should reflect 2 resources after environment change"
  }

  assert {
    condition     = endswith(local_file.example_map["app.txt"].filename, "prod_app.txt")
    error_message = "filename should be prefixed with environment 'prod'"
  }

  assert {
    condition     = local_file.example_map["infra.txt"].content == "Production infrastructure"
    error_message = "infra.txt content should match provided value"
  }
}