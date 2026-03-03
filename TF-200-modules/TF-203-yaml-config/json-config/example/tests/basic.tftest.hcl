# TF-203/json-config Test: jsondecode() and JSON-driven configuration
# No input variables (reads servers.json from module directory)
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: jsondecode() parses JSON files; for expressions filter data;
# jsonencode() generates JSON output. servers.json has 3 servers: 2 enabled, 1 disabled.

run "creates_config_files_for_enabled_servers_only" {
  command = apply

  assert {
    condition     = length(local_file.server_configs) == 2
    error_message = "Expected 2 config files (web-01 and api-01 are enabled; db-01 is disabled)"
  }

  assert {
    condition     = contains(keys(local_file.server_configs), "web-01")
    error_message = "web-01 is enabled and should have a config file"
  }

  assert {
    condition     = contains(keys(local_file.server_configs), "api-01")
    error_message = "api-01 is enabled and should have a config file"
  }

  assert {
    condition     = !contains(keys(local_file.server_configs), "db-01")
    error_message = "db-01 is disabled and should NOT have a config file"
  }
}

run "server_config_content_is_correct" {
  command = apply

  assert {
    condition     = strcontains(local_file.server_configs["web-01"].content, "role = \"frontend\"")
    error_message = "web-01 config should contain role = frontend"
  }

  assert {
    condition     = strcontains(local_file.server_configs["web-01"].content, "port = 80")
    error_message = "web-01 config should contain port = 80"
  }

  assert {
    condition     = strcontains(local_file.server_configs["api-01"].content, "role = \"backend\"")
    error_message = "api-01 config should contain role = backend"
  }

  assert {
    condition     = strcontains(local_file.server_configs["api-01"].content, "port = 8080")
    error_message = "api-01 config should contain port = 8080"
  }

  assert {
    condition     = strcontains(local_file.server_configs["web-01"].content, "env  = \"dev\"")
    error_message = "config should reflect environment from servers.json (dev)"
  }
}

run "deployment_manifest_is_generated" {
  command = apply

  assert {
    condition     = endswith(local_file.deployment_manifest.filename, "deployment-manifest.json")
    error_message = "deployment manifest should be written to deployment-manifest.json"
  }

  assert {
    condition     = strcontains(local_file.deployment_manifest.content, "\"environment\":\"dev\"")
    error_message = "deployment manifest should contain environment from servers.json"
  }

  assert {
    condition     = strcontains(local_file.deployment_manifest.content, "\"total_servers\":3")
    error_message = "deployment manifest should show total_servers = 3"
  }

  assert {
    condition     = strcontains(local_file.deployment_manifest.content, "\"enabled_servers\":2")
    error_message = "deployment manifest should show enabled_servers = 2"
  }

  assert {
    condition     = strcontains(local_file.deployment_manifest.content, "\"disabled_servers\":1")
    error_message = "deployment manifest should show disabled_servers = 1"
  }
}

run "outputs_are_correct" {
  command = apply

  assert {
    condition     = length(output.enabled_servers) == 2
    error_message = "enabled_servers output should contain 2 servers"
  }

  assert {
    condition     = output.disabled_server_count == 1
    error_message = "disabled_server_count output should be 1"
  }

  assert {
    condition     = output.config_summary.environment == "dev"
    error_message = "config_summary.environment should be 'dev' from servers.json"
  }

  assert {
    condition     = output.config_summary.total_servers == 3
    error_message = "config_summary.total_servers should be 3"
  }
}