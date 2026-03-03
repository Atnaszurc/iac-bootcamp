# TF-306/4-encoding-functions Test: encoding function results
# Variables: environment (default "production"), app_replicas (default 3),
#            enable_monitoring (default true), s3_buckets (default 3), vm_packages (default 4)
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: jsonencode(), jsondecode(), yamlencode(), yamldecode(),
# base64encode(), base64decode(), tostring(), tonumber(), tobool(), toset()

run "creates_all_output_files" {
  command = apply

  assert {
    condition     = endswith(local_file.app_config_json.filename, "app-config.json")
    error_message = "App config JSON should be written to output/app-config.json"
  }

  assert {
    condition     = endswith(local_file.iam_policy_json.filename, "iam-policy.json")
    error_message = "IAM policy JSON should be written to output/iam-policy.json"
  }

  assert {
    condition     = endswith(local_file.cloud_init_yaml.filename, "cloud-init.yaml")
    error_message = "Cloud-init YAML should be written to output/cloud-init.yaml"
  }

  assert {
    condition     = endswith(local_file.startup_script_b64.filename, "startup-script.b64")
    error_message = "Base64 startup script should be written to output/startup-script.b64"
  }
}

run "jsonencode_produces_valid_json" {
  command = apply

  assert {
    condition     = strcontains(local_file.app_config_json.content, "\"environment\":\"production\"")
    error_message = "jsonencode() should produce JSON with environment=production"
  }

  assert {
    condition     = strcontains(local_file.app_config_json.content, "\"replicas\":3")
    error_message = "jsonencode() should produce JSON with replicas=3"
  }

  assert {
    condition     = strcontains(local_file.app_config_json.content, "\"monitoring\":true")
    error_message = "jsonencode() should produce JSON with monitoring=true"
  }
}

run "iam_policy_has_correct_number_of_statements" {
  command = apply

  assert {
    condition     = strcontains(local_file.iam_policy_json.content, "\"Version\":\"2012-10-17\"")
    error_message = "IAM policy should contain Version field"
  }

  assert {
    condition     = strcontains(local_file.iam_policy_json.content, "logs-bucket")
    error_message = "IAM policy should contain logs-bucket from default s3_buckets"
  }

  assert {
    condition     = strcontains(local_file.iam_policy_json.content, "data-bucket")
    error_message = "IAM policy should contain data-bucket from default s3_buckets"
  }

  assert {
    condition     = strcontains(local_file.iam_policy_json.content, "backup-bucket")
    error_message = "IAM policy should contain backup-bucket from default s3_buckets"
  }
}

run "yamlencode_produces_cloud_init_yaml" {
  command = apply

  assert {
    condition     = startswith(local_file.cloud_init_yaml.content, "#cloud-config\n")
    error_message = "Cloud-init YAML should start with '#cloud-config' header"
  }

  assert {
    condition     = strcontains(local_file.cloud_init_yaml.content, "nginx")
    error_message = "Cloud-init YAML should contain nginx from default vm_packages"
  }
}

run "base64_round_trip_succeeds" {
  command = apply

  assert {
    condition     = output.base64_round_trip_success == true
    error_message = "base64encode() followed by base64decode() should return the original string"
  }
}

run "type_conversions_are_correct" {
  command = apply

  assert {
    condition     = output.type_conversions.replicas_as_string == "3"
    error_message = "tostring(3) should produce '3'"
  }

  assert {
    condition     = output.type_conversions.monitoring_as_string == "true"
    error_message = "tostring(true) should produce 'true'"
  }

  assert {
    condition     = output.type_conversions.port_as_number == 8080
    error_message = "tonumber('8080') should produce 8080"
  }

  assert {
    condition     = output.type_conversions.flag_as_bool == true
    error_message = "tobool('true') should produce true"
  }
}

run "toset_deduplicates_packages" {
  command = apply

  # Default vm_packages has 4 unique items; packages_with_dupes has 5 items but only 3 unique
  assert {
    condition     = length(output.unique_packages) == 3
    error_message = "toset() should deduplicate ['nginx','curl','nginx','git','curl'] to 3 unique items"
  }

  assert {
    condition     = contains(tolist(output.unique_packages), "nginx")
    error_message = "Deduplicated set should contain 'nginx'"
  }

  assert {
    condition     = contains(tolist(output.unique_packages), "curl")
    error_message = "Deduplicated set should contain 'curl'"
  }

  assert {
    condition     = contains(tolist(output.unique_packages), "git")
    error_message = "Deduplicated set should contain 'git'"
  }
}