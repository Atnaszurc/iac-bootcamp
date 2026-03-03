# TF-102/3-env-vars Test: count and for_each loops with local_file
# Variables: file_contents (list, has default), file_names (map, has default)
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)

run "creates_count_files_with_defaults" {
  command = apply

  assert {
    condition     = length(local_file.example_count) == 3
    error_message = "Expected 3 files from count loop (default file_contents has 3 items)"
  }
}

run "creates_for_each_files_with_defaults" {
  command = apply

  assert {
    condition     = length(local_file.example_for_each) == 3
    error_message = "Expected 3 files from for_each loop (default file_names has 3 entries)"
  }
}

run "creates_hardcoded_fruit_files" {
  command = apply

  assert {
    condition     = length(local_file.example_for_each_set) == 3
    error_message = "Expected 3 fruit files (apple, banana, cherry)"
  }

  assert {
    condition     = local_file.example_for_each_set["apple"].content == "I like apple"
    error_message = "apple file content should be 'I like apple'"
  }

  assert {
    condition     = local_file.example_for_each_set["banana"].content == "I like banana"
    error_message = "banana file content should be 'I like banana'"
  }
}

run "creates_custom_count_files" {
  command = apply

  variables {
    file_contents = ["Alpha", "Beta"]
  }

  assert {
    condition     = length(local_file.example_count) == 2
    error_message = "Expected 2 files when file_contents has 2 items"
  }
}