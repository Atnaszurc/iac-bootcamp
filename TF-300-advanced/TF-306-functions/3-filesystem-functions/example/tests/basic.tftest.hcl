# TF-306/3-filesystem-functions Test: file(), templatefile(), fileset(), path variables
# Variables: environment (default "production"), app_port (default 8080), enabled_features (default list)
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: templatefile() renders .tftpl files with variable substitution;
# file() reads raw file content; path.module/path.root/path.cwd reference paths.
# Note: The template file is created by local_file.app_conf_template before being read.

run "creates_template_and_output_files" {
  command = apply

  assert {
    condition     = fileexists("${path.module}/templates/app.conf.tftpl")
    error_message = "Template file should exist at templates/app.conf.tftpl"
  }

  assert {
    condition     = endswith(local_file.app_config_output.filename, "app.conf")
    error_message = "Rendered app config should be written to output/app.conf"
  }

  assert {
    condition     = endswith(local_file.staging_config_output.filename, "staging-app.conf")
    error_message = "Staging config should be written to output/staging-app.conf"
  }

  assert {
    condition     = endswith(local_file.filesystem_functions_summary.filename, "filesystem-functions-summary.txt")
    error_message = "Summary should be written to output/filesystem-functions-summary.txt"
  }
}

run "rendered_app_config_contains_correct_values" {
  command = apply

  assert {
    condition     = strcontains(local_file.app_config_output.content, "environment = production")
    error_message = "Rendered config should contain default environment 'production'"
  }

  assert {
    condition     = strcontains(local_file.app_config_output.content, "port        = 8080")
    error_message = "Rendered config should contain default app_port 8080"
  }

  assert {
    condition     = strcontains(local_file.app_config_output.content, "host        = 0.0.0.0")
    error_message = "Rendered config should contain host 0.0.0.0"
  }

  assert {
    condition     = strcontains(local_file.app_config_output.content, "authentication = enabled")
    error_message = "Rendered config should list authentication as enabled feature"
  }

  assert {
    condition     = strcontains(local_file.app_config_output.content, "db_name") && strcontains(local_file.app_config_output.content, "production_appdb")
    error_message = "Rendered config should contain db_name with environment prefix"
  }
}

run "staging_config_uses_hardcoded_staging_values" {
  command = apply

  assert {
    condition     = strcontains(local_file.staging_config_output.content, "environment = staging")
    error_message = "Staging config should show environment = staging"
  }

  assert {
    condition     = strcontains(local_file.staging_config_output.content, "port        = 443")
    error_message = "Staging config should use port 443"
  }

  assert {
    condition     = strcontains(local_file.staging_config_output.content, "host        = 10.0.1.10")
    error_message = "Staging config should use host 10.0.1.10"
  }
}

run "outputs_are_populated" {
  command = apply

  assert {
    condition     = strcontains(output.rendered_app_config, "environment = production")
    error_message = "rendered_app_config output should contain environment = production"
  }

  assert {
    condition     = endswith(output.template_file_path, "app.conf.tftpl")
    error_message = "template_file_path output should point to the .tftpl file"
  }

  assert {
    condition     = output.fileset_example == toset(["app.conf.tftpl", "nginx.conf.tftpl", "systemd.service.tftpl"])
    error_message = "fileset_example output should contain the 3 simulated template filenames"
  }
}