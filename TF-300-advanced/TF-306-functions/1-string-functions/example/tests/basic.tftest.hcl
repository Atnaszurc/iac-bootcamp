# TF-306/1-string-functions Test: string function results
# Variables: project (default "myapp"), environment (default "production"),
#            component (default "web server"), servers (default list)
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: format(), replace(), split(), join(), trim(), upper(), lower(),
# regex(), regexall(), substr() — all demonstrated via a results.txt file.

run "creates_results_file" {
  command = apply

  assert {
    condition     = endswith(local_file.string_function_results.filename, "results.txt")
    error_message = "Results should be written to results.txt"
  }
}

run "format_function_results_are_correct" {
  command = apply

  assert {
    condition     = strcontains(local_file.string_function_results.content, "vm_name_formatted = vm-production-web server")
    error_message = "format() should produce 'vm-production-web server' with default vars"
  }

  assert {
    condition     = strcontains(local_file.string_function_results.content, "padded_index      = 005")
    error_message = "format('%03d', 5) should produce '005'"
  }

  assert {
    condition     = strcontains(local_file.string_function_results.content, "dns_name          = myapp.production.example.com")
    error_message = "format() should produce 'myapp.production.example.com'"
  }
}

run "replace_and_case_functions_are_correct" {
  command = apply

  assert {
    condition     = strcontains(local_file.string_function_results.content, "safe_component    = web-server")
    error_message = "replace() should convert 'web server' to 'web-server' (space → dash)"
  }

  assert {
    condition     = strcontains(local_file.string_function_results.content, "upper_env         = PRODUCTION")
    error_message = "upper() should convert 'production' to 'PRODUCTION'"
  }

  assert {
    condition     = strcontains(local_file.string_function_results.content, "lower_env         = production")
    error_message = "lower() should keep 'production' as 'production'"
  }
}

run "split_and_join_functions_are_correct" {
  command = apply

  assert {
    condition     = strcontains(local_file.string_function_results.content, "network           = 10.0.0.0")
    error_message = "split('/') on CIDR should extract network address"
  }

  assert {
    condition     = strcontains(local_file.string_function_results.content, "prefix_len        = 24")
    error_message = "split('/') on CIDR should extract prefix length"
  }

  assert {
    condition     = strcontains(local_file.string_function_results.content, "package_csv       = nginx, curl, wget, git")
    error_message = "join(', ') should produce comma-separated package list"
  }
}

run "regex_functions_are_correct" {
  command = apply

  assert {
    condition     = strcontains(local_file.string_function_results.content, "version_number    = 1.9.5")
    error_message = "regex() should extract version number '1.9.5' from version string"
  }

  assert {
    condition     = strcontains(local_file.string_function_results.content, "ip_addresses      = 10.0.0.1, 10.0.0.2, 10.0.0.3")
    error_message = "regexall() should extract all 3 IP addresses"
  }
}

run "substr_function_is_correct" {
  command = apply

  assert {
    condition     = strcontains(local_file.string_function_results.content, "short_name        = my-very-long-resourc")
    error_message = "substr(0, 20) should truncate to first 20 chars: 'my-very-long-resourc'"
  }
}

run "combined_resource_name_is_correct" {
  command = apply

  assert {
    condition     = strcontains(local_file.string_function_results.content, "resource_name     = myapp-production-web-server")
    error_message = "Combined resource name should be 'myapp-production-web-server' (space replaced, truncated to 63)"
  }
}