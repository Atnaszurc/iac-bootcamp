# Tests for AZ-201: Setup & Authentication
# Uses mock_provider to test configuration without real Azure credentials.
# Validates provider configuration and output structure.

mock_provider "azurerm" {
  mock_data "azurerm_subscription" {
    defaults = {
      subscription_id  = "00000000-0000-0000-0000-000000000001"
      display_name     = "Mock Training Subscription"
      tenant_id        = "00000000-0000-0000-0000-000000000002"
      state            = "Enabled"
    }
  }

  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id   = "00000000-0000-0000-0000-000000000002"
      client_id   = "00000000-0000-0000-0000-000000000003"
      object_id   = "00000000-0000-0000-0000-000000000004"
    }
  }
}

# ---------------------------------------------------------------
# Test 1: Subscription data source returns mocked values
# ---------------------------------------------------------------
run "subscription_data_source" {
  command = plan

  assert {
    condition     = output.subscription_id == "00000000-0000-0000-0000-000000000001"
    error_message = "subscription_id output should match the mocked subscription data source"
  }

  assert {
    condition     = output.subscription_display_name == "Mock Training Subscription"
    error_message = "subscription_display_name output should match the mocked display name"
  }
}

# ---------------------------------------------------------------
# Test 2: Client config data source returns mocked values
# ---------------------------------------------------------------
run "client_config_data_source" {
  command = plan

  assert {
    condition     = output.tenant_id == "00000000-0000-0000-0000-000000000002"
    error_message = "tenant_id output should match the mocked client config"
  }

  assert {
    condition     = output.client_id == "00000000-0000-0000-0000-000000000003"
    error_message = "client_id output should match the mocked client config"
  }
}

# ---------------------------------------------------------------
# Test 3: Empty subscription_id variable is accepted (uses env var)
# ---------------------------------------------------------------
run "empty_subscription_id" {
  command = plan

  variables {
    subscription_id = ""
  }

  assert {
    condition     = output.subscription_id != ""
    error_message = "subscription_id output should come from the data source, not the variable"
  }
}