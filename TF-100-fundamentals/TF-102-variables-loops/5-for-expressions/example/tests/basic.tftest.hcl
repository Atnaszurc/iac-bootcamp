# Tests for TF-102 Section 5: for Expressions
# All tests use command = plan (local provider, no external dependencies)

# ---------------------------------------------------------------
# Test 1: Default variables — verify list transformations
# ---------------------------------------------------------------
run "default_list_transformations" {
  command = plan

  assert {
    condition     = length(output.all_names) == 5
    error_message = "all_names should contain all 5 servers from the default list"
  }

  assert {
    condition     = length(output.enabled_names) == 3
    error_message = "enabled_names should contain only the 3 enabled servers (web-01, api-01, db-01)"
  }

  assert {
    condition     = contains(output.enabled_names, "web-01")
    error_message = "enabled_names should include web-01 (enabled = true)"
  }

  assert {
    condition     = !contains(output.enabled_names, "web-02")
    error_message = "enabled_names should NOT include web-02 (enabled = false)"
  }

  assert {
    condition     = !contains(output.enabled_names, "cache-01")
    error_message = "enabled_names should NOT include cache-01 (enabled = false)"
  }
}

# ---------------------------------------------------------------
# Test 2: Default variables — verify map transformations
# ---------------------------------------------------------------
run "default_map_transformations" {
  command = plan

  assert {
    condition     = length(output.name_to_role) == 5
    error_message = "name_to_role should contain all 5 servers"
  }

  assert {
    condition     = output.name_to_role["web-01"] == "frontend"
    error_message = "name_to_role[web-01] should be 'frontend'"
  }

  assert {
    condition     = output.name_to_role["db-01"] == "database"
    error_message = "name_to_role[db-01] should be 'database'"
  }

  assert {
    condition     = length(output.enabled_map) == 3
    error_message = "enabled_map should contain only the 3 enabled servers"
  }

  assert {
    condition     = !contains(keys(output.enabled_map), "web-02")
    error_message = "enabled_map should NOT contain web-02 (disabled)"
  }
}

# ---------------------------------------------------------------
# Test 3: Tag transformations with default environment
# ---------------------------------------------------------------
run "tag_transformations_default_env" {
  command = plan

  assert {
    condition     = length(output.tag_strings) == 3
    error_message = "tag_strings should have one entry per base_tag (3 default tags)"
  }

  assert {
    condition     = length(output.prefixed_tags) == 3
    error_message = "prefixed_tags should have same count as base_tags"
  }

  assert {
    condition     = contains(keys(output.prefixed_tags), "dev_project")
    error_message = "prefixed_tags should contain 'dev_project' key (default env=dev)"
  }

  assert {
    condition     = contains(keys(output.prefixed_tags), "dev_owner")
    error_message = "prefixed_tags should contain 'dev_owner' key (default env=dev)"
  }
}

# ---------------------------------------------------------------
# Test 4: Custom environment changes prefixed tag keys
# ---------------------------------------------------------------
run "custom_environment_prefix" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = contains(keys(output.prefixed_tags), "prod_project")
    error_message = "prefixed_tags should use 'prod' prefix when environment=prod"
  }

  assert {
    condition     = !contains(keys(output.prefixed_tags), "dev_project")
    error_message = "prefixed_tags should NOT have 'dev_' prefix when environment=prod"
  }
}

# ---------------------------------------------------------------
# Test 5: Custom server list — for expression filtering
# ---------------------------------------------------------------
run "custom_server_list_filtering" {
  command = plan

  variables {
    environment = "staging"
    servers = [
      { name = "app-01", role = "backend",  enabled = true  },
      { name = "app-02", role = "backend",  enabled = false },
      { name = "app-03", role = "backend",  enabled = true  },
    ]
  }

  assert {
    condition     = length(output.all_names) == 3
    error_message = "all_names should contain all 3 custom servers"
  }

  assert {
    condition     = length(output.enabled_names) == 2
    error_message = "enabled_names should contain only 2 enabled servers"
  }

  assert {
    condition     = contains(output.enabled_names, "app-01")
    error_message = "enabled_names should include app-01 (enabled = true)"
  }

  assert {
    condition     = !contains(output.enabled_names, "app-02")
    error_message = "enabled_names should NOT include app-02 (enabled = false)"
  }
}

# ---------------------------------------------------------------
# Test 6: display_strings contain status indicators
# ---------------------------------------------------------------
run "display_strings_format" {
  command = plan

  assert {
    condition     = length(output.display_strings) == 5
    error_message = "display_strings should have one entry per server"
  }

  assert {
    condition     = can(regex("active", output.display_strings[0]))
    error_message = "First display string (web-01, enabled) should contain 'active'"
  }

  assert {
    condition     = can(regex("disabled", output.display_strings[1]))
    error_message = "Second display string (web-02, disabled) should contain 'disabled'"
  }
}