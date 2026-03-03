# TF-201/moved-blocks Test: renamed resources with moved blocks
# Variables: environment (string, default = "dev")
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: moved blocks allow renaming resources without destroy/recreate.
# This test validates the AFTER state (renamed resources: web, api, db).

run "creates_three_config_files" {
  command = apply

  assert {
    condition     = local_file.web.content == "server = web\nport = 80\nenvironment = dev"
    error_message = "web.conf content should contain web server config with default environment"
  }

  assert {
    condition     = local_file.api.content == "server = api\nport = 8080\nenvironment = dev"
    error_message = "api.conf content should contain api server config with default environment"
  }

  assert {
    condition     = local_file.db.content == "server = db\nport = 5432\nenvironment = dev"
    error_message = "db.conf content should contain database config with default environment"
  }

  assert {
    condition     = endswith(local_file.web.filename, "web.conf")
    error_message = "web resource should write to web.conf"
  }

  assert {
    condition     = endswith(local_file.api.filename, "api.conf")
    error_message = "api resource should write to api.conf"
  }

  assert {
    condition     = endswith(local_file.db.filename, "db.conf")
    error_message = "db resource should write to db.conf"
  }
}

run "creates_config_files_with_custom_environment" {
  command = apply

  variables {
    environment = "staging"
  }

  assert {
    condition     = local_file.web.content == "server = web\nport = 80\nenvironment = staging"
    error_message = "web.conf should reflect staging environment"
  }

  assert {
    condition     = local_file.db.content == "server = db\nport = 5432\nenvironment = staging"
    error_message = "db.conf should reflect staging environment"
  }
}