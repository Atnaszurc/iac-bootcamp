# Test file for deprecation detection examples
# Terraform 1.15+

run "verify_documentation_files_created" {
  command = apply

  assert {
    condition     = fileexists(local_file.deprecation_example.filename)
    error_message = "Deprecation demo file was not created"
  }

  assert {
    condition     = fileexists(local_file.common_patterns.filename)
    error_message = "Common patterns file was not created"
  }

  assert {
    condition     = fileexists(local_file.migration_checklist.filename)
    error_message = "Migration checklist file was not created"
  }
}

run "verify_output_structure" {
  command = apply

  assert {
    condition     = length(keys(output.example_files)) == 3
    error_message = "Expected 3 example files in output"
  }

  assert {
    condition     = length(keys(output.key_points)) == 7
    error_message = "Expected 7 key points in output"
  }
}

run "verify_file_content" {
  command = apply

  assert {
    condition     = length(local_file.deprecation_example.content) > 100
    error_message = "Deprecation demo file content is too short"
  }

  assert {
    condition     = length(local_file.common_patterns.content) > 100
    error_message = "Common patterns file content is too short"
  }

  assert {
    condition     = length(local_file.migration_checklist.content) > 100
    error_message = "Migration checklist file content is too short"
  }
}