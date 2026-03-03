# Tests for AWS-201: Setup & Authentication
# Uses mock_provider to test configuration without real AWS credentials.
# Validates provider configuration, variable defaults, and output structure.

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/terraform-test"
      user_id    = "AIDAEXAMPLEUSERID"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region      = "eu-west-1"  # v6: use 'region' instead of 'name'
      description = "Europe (Ireland)"
    }
  }

  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
      state = "available"
    }
  }
}

# ---------------------------------------------------------------
# Test 1: Default variable values produce valid plan
# ---------------------------------------------------------------
run "default_variables" {
  command = plan

  assert {
    condition     = output.region == "eu-west-1"
    error_message = "Region output should match the mocked aws_region data source"
  }

  assert {
    condition     = output.account_id == "123456789012"
    error_message = "account_id output should match the mocked caller identity"
  }

  assert {
    condition     = output.caller_arn == "arn:aws:iam::123456789012:user/terraform-test"
    error_message = "caller_arn output should match the mocked ARN"
  }
}

# ---------------------------------------------------------------
# Test 2: Custom region variable
# ---------------------------------------------------------------
run "custom_region" {
  command = plan

  variables {
    aws_region  = "us-east-1"
    environment = "production"
  }

  assert {
    condition     = length(output.availability_zones) > 0
    error_message = "availability_zones output should be non-empty"
  }

  assert {
    condition     = output.account_id != ""
    error_message = "account_id should not be empty"
  }
}

# ---------------------------------------------------------------
# Test 3: Environment variable is accepted
# ---------------------------------------------------------------
run "environment_staging" {
  command = plan

  variables {
    environment = "staging"
  }

  assert {
    condition     = output.account_id == "123456789012"
    error_message = "Mock account_id should be consistent regardless of environment"
  }
}