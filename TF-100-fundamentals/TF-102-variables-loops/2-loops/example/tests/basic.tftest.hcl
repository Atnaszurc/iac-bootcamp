# TF-102/2-loops Test: Variable-driven local_file resources
# Variables: file1_content, file1_name, file2_content, file2_name (all have defaults)
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)
#
# NOTE: variables.tf and main.tf have a variable name mismatch in this example.
# main.tf uses: file1_content, file1_name, file2_content, file2_name
# variables.tf defines: file_contents (list), file_names (map)
# The test supplies the variables that main.tf actually references.

run "creates_files_with_defaults" {
  command = apply

  variables {
    file1_content = "Default content for file 1"
    file1_name    = "file1.txt"
    file2_content = "Default content for file 2"
    file2_name    = "file2.txt"
  }

  assert {
    condition     = local_file.example1.content == "Default content for file 1"
    error_message = "example1 content should match file1_content variable"
  }

  assert {
    condition     = local_file.example2.content == "Default content for file 2"
    error_message = "example2 content should match file2_content variable"
  }
}

run "creates_files_with_custom_names" {
  command = apply

  variables {
    file1_content = "Custom A"
    file1_name    = "custom_a.txt"
    file2_content = "Custom B"
    file2_name    = "custom_b.txt"
  }

  assert {
    condition     = local_file.example1.content == "Custom A"
    error_message = "example1 content should match custom file1_content"
  }

  assert {
    condition     = local_file.example2.content == "Custom B"
    error_message = "example2 content should match custom file2_content"
  }
}