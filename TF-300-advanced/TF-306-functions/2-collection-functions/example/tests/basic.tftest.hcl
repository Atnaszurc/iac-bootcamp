# TF-306/2-collection-functions Test: collection function results
# Variables: environments (default 3), regions (default 2), global_tags, resource_tags
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)
#
# Teaching focus: flatten(), merge(), setproduct(), zipmap(), distinct(),
# compact(), concat(), keys(), values(), lookup()

run "creates_deployment_configs_for_all_env_region_combos" {
  command = apply

  # 3 environments × 2 regions = 6 deployment configs
  assert {
    condition     = length(local_file.deployment_config) == 6
    error_message = "Expected 6 deployment configs (3 envs × 2 regions)"
  }

  assert {
    condition     = contains(keys(local_file.deployment_config), "dev-eastus")
    error_message = "Should have a config for dev-eastus"
  }

  assert {
    condition     = contains(keys(local_file.deployment_config), "prod-westeurope")
    error_message = "Should have a config for prod-westeurope"
  }
}

run "deployment_config_content_is_correct" {
  command = apply

  assert {
    condition     = strcontains(local_file.deployment_config["dev-eastus"].content, "environment = dev")
    error_message = "dev-eastus config should show environment = dev"
  }

  assert {
    condition     = strcontains(local_file.deployment_config["dev-eastus"].content, "region      = eastus")
    error_message = "dev-eastus config should show region = eastus"
  }

  assert {
    condition     = strcontains(local_file.deployment_config["staging-westeurope"].content, "environment = staging")
    error_message = "staging-westeurope config should show environment = staging"
  }
}

run "collection_results_file_is_created" {
  command = apply

  assert {
    condition     = endswith(local_file.collection_results.filename, "results.txt")
    error_message = "Collection results should be written to results.txt"
  }
}

run "flatten_function_results_are_correct" {
  command = apply

  assert {
    condition     = strcontains(local_file.collection_results.content, "flat_servers          = web-01, web-02, api-01, db-01, db-02")
    error_message = "flatten() should produce flat list of all servers"
  }
}

run "merge_function_results_are_correct" {
  command = apply

  assert {
    condition     = strcontains(local_file.collection_results.content, "\"managed_by\":\"terraform\"")
    error_message = "merge() result should contain global tag managed_by=terraform"
  }

  assert {
    condition     = strcontains(local_file.collection_results.content, "\"component\":\"web-server\"")
    error_message = "merge() result should contain resource tag component=web-server (overrides global)"
  }
}

run "distinct_and_compact_functions_are_correct" {
  command = apply

  assert {
    condition     = strcontains(local_file.collection_results.content, "unique_tags = web, frontend, nginx")
    error_message = "distinct() should remove duplicate tags, keeping order of first occurrence"
  }

  assert {
    condition     = strcontains(local_file.collection_results.content, "clean_list = web, api, db")
    error_message = "compact() should remove empty strings from list"
  }
}

run "concat_and_lookup_functions_are_correct" {
  command = apply

  assert {
    condition     = strcontains(local_file.collection_results.content, "all_packages = curl, wget, nginx, git")
    error_message = "concat() should combine base and extra packages"
  }

  assert {
    condition     = strcontains(local_file.collection_results.content, "default_size  = 2cpu-4gb")
    error_message = "lookup() with missing key 'xlarge' should return default '2cpu-4gb'"
  }

  assert {
    condition     = strcontains(local_file.collection_results.content, "selected_size = 4cpu-8gb")
    error_message = "lookup() for 'large' should return '4cpu-8gb'"
  }
}