# TF-102/4-functions Test: for_each with map variable and environment prefix
# Variables: file_contents (map, has default), environment (NO default - must be supplied)
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)

run "creates_files_with_dev_environment" {
  command = apply

  variables {
    environment = "dev"
  }

  assert {
    condition     = length(local_file.example_map) == 3
    error_message = "Expected 3 files (default file_contents has 3 entries)"
  }

  assert {
    condition     = local_file.example_map["file1.txt"].content == "This is the content of file 1"
    error_message = "file1.txt content should match default value"
  }

  assert {
    condition     = endswith(local_file.example_map["file1.txt"].filename, "dev_file1.txt")
    error_message = "filename should be prefixed with environment 'dev'"
  }
}

run "creates_files_with_prod_environment" {
  command = apply

  variables {
    environment = "prod"
    file_contents = {
      "app.txt"    = "Production app config"
      "db.txt"     = "Production db config"
    }
  }

  assert {
    condition     = length(local_file.example_map) == 2
    error_message = "Expected 2 files with custom file_contents"
  }

  assert {
    condition     = endswith(local_file.example_map["app.txt"].filename, "prod_app.txt")
    error_message = "filename should be prefixed with environment 'prod'"
  }
}