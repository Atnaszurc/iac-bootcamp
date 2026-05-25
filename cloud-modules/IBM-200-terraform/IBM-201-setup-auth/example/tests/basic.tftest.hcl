mock_provider "ibm" {
  mock_data "ibm_resource_group" {
    defaults = {
      id   = "6f5d9c8a-1234-4abc-9def-1234567890ab"
      name = "Default"
    }
  }
}

variables {
  ibm_region          = "us-south"
  resource_group_name = "Default"
  environment         = "dev"
}

run "plan_setup_auth_example" {
  command = plan

  assert {
    condition     = output.provider_source == "IBM-Cloud/ibm"
    error_message = "Expected IBM Cloud provider source output."
  }

  assert {
    condition     = output.provider_region == "us-south"
    error_message = "Expected provider region to match test input."
  }

  assert {
    condition     = output.resource_group_name == "Default"
    error_message = "Expected mocked resource group name to be returned."
  }

  assert {
    condition     = output.resource_group_id == "6f5d9c8a-1234-4abc-9def-1234567890ab"
    error_message = "Expected mocked resource group ID to be returned."
  }

  assert {
    condition     = output.environment == "dev"
    error_message = "Expected normalized environment output to be dev."
  }

  assert {
    condition     = length(output.common_tags) == 4
    error_message = "Expected four starter tags."
  }

  assert {
    condition     = contains(output.common_tags, "training")
    error_message = "Expected common_tags to include training."
  }

  assert {
    condition     = contains(output.common_tags, "ibm-cloud")
    error_message = "Expected common_tags to include ibm-cloud."
  }

  assert {
    condition     = contains(output.common_tags, "terraform")
    error_message = "Expected common_tags to include terraform."
  }

  assert {
    condition     = contains(output.common_tags, "environment:dev")
    error_message = "Expected common_tags to include the normalized environment tag."
  }
}
