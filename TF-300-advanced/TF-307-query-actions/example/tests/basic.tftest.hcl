# TF-307 Test: actions triggered from resource lifecycle events
# Uses: command = plan for configuration checks, command = apply to run the
#       actions for real (local_command only writes under ./out)
# Provider: hashicorp/local (real provider — no credentials needed)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: action_trigger wiring, caller, for_each + shared actions

run "plan_default_services" {
  command = plan

  assert {
    condition     = length(local_file.service_config) == 2
    error_message = "Default configuration should create one config file per service (api, worker)"
  }

  assert {
    condition     = local_file.service_config["api"].filename == "./out/api.conf"
    error_message = "Service config files should be written to ./out/<service>.conf"
  }

  assert {
    condition     = strcontains(local_file.service_config["worker"].content, "port        = 9090")
    error_message = "Worker config should contain its port"
  }
}

run "plan_custom_environment" {
  command = plan

  variables {
    environment = "prod"
    app_version = "2.0.0"
  }

  assert {
    condition     = strcontains(local_file.service_config["api"].content, "environment = prod")
    error_message = "Config content should use the environment variable"
  }

  assert {
    condition     = strcontains(local_file.service_config["api"].content, "version     = 2.0.0")
    error_message = "Config content should use the app_version variable"
  }
}

run "apply_invokes_actions" {
  command = apply

  assert {
    condition     = output.audit_log == "./out/audit.log"
    error_message = "Actions should log to ./out/audit.log"
  }

  assert {
    condition     = keys(output.config_files) == ["api", "worker"]
    error_message = "Apply should create config files for api and worker"
  }
}
