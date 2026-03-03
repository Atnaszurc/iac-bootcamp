# MC-301: Multi-Cloud Strategy & Design - Tests
# Uses mock_provider for both AWS and Azure (no credentials required)
# Requires Terraform >= 1.7.0

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
      user_id    = "AIDATEST123456789012"
    }
  }
}

mock_provider "azurerm" {}

# ---------------------------------------------------------------------------
# Run 1: Default dev environment configuration
# ---------------------------------------------------------------------------

run "dev_environment_defaults" {
  command = plan

  assert {
    condition     = var.environment == "dev"
    error_message = "Default environment should be 'dev'."
  }

  assert {
    condition     = local.name_prefix == "mc301-demo-dev"
    error_message = "Name prefix should be 'mc301-demo-dev'."
  }

  assert {
    condition     = local.config.aws_instance_type == "t3.micro"
    error_message = "Dev environment should use t3.micro."
  }

  assert {
    condition     = local.config.azure_vm_size == "Standard_B1s"
    error_message = "Dev environment should use Standard_B1s."
  }

  assert {
    condition     = local.config.replicas == 1
    error_message = "Dev environment should have 1 replica."
  }
}

# ---------------------------------------------------------------------------
# Run 2: Common tags applied consistently across both clouds
# ---------------------------------------------------------------------------

run "consistent_tagging" {
  command = plan

  variables {
    project_name = "tagging-test"
    environment  = "staging"
    team_name    = "infra-team"
    cost_center  = "CC-9999"
  }

  assert {
    condition     = local.common_tags["Project"] == "tagging-test"
    error_message = "Common tags must include correct Project."
  }

  assert {
    condition     = local.common_tags["Environment"] == "staging"
    error_message = "Common tags must include correct Environment."
  }

  assert {
    condition     = local.common_tags["Team"] == "infra-team"
    error_message = "Common tags must include correct Team."
  }

  assert {
    condition     = local.common_tags["CostCenter"] == "CC-9999"
    error_message = "Common tags must include correct CostCenter."
  }

  assert {
    condition     = local.common_tags["ManagedBy"] == "Terraform"
    error_message = "Common tags must include ManagedBy = Terraform."
  }
}

# ---------------------------------------------------------------------------
# Run 3: AWS resources use correct CIDR blocks
# ---------------------------------------------------------------------------

run "aws_networking_config" {
  command = plan

  variables {
    project_name = "network-test"
    environment  = "dev"
  }

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "AWS VPC CIDR should be 10.0.0.0/16."
  }

  assert {
    condition     = aws_subnet.public.cidr_block == "10.0.1.0/24"
    error_message = "AWS public subnet CIDR should be 10.0.1.0/24."
  }

  assert {
    condition     = aws_vpc.main.enable_dns_hostnames == true
    error_message = "AWS VPC should have DNS hostnames enabled."
  }
}

# ---------------------------------------------------------------------------
# Run 4: Azure resources use correct address spaces
# ---------------------------------------------------------------------------

run "azure_networking_config" {
  command = plan

  variables {
    project_name = "azure-net-test"
    environment  = "dev"
  }

  assert {
    condition     = tolist(azurerm_virtual_network.main.address_space)[0] == "10.1.0.0/16"
    error_message = "Azure VNet address space should be 10.1.0.0/16."
  }

  assert {
    condition     = azurerm_subnet.public.address_prefixes[0] == "10.1.1.0/24"
    error_message = "Azure public subnet should be 10.1.1.0/24."
  }

  assert {
    condition     = azurerm_resource_group.main.location == "West Europe"
    error_message = "Azure resource group should be in West Europe."
  }
}

# ---------------------------------------------------------------------------
# Run 5: Production environment uses larger instance sizes
# ---------------------------------------------------------------------------

run "prod_environment_sizing" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = local.config.aws_instance_type == "t3.medium"
    error_message = "Prod environment should use t3.medium."
  }

  assert {
    condition     = local.config.azure_vm_size == "Standard_D2s_v3"
    error_message = "Prod environment should use Standard_D2s_v3."
  }

  assert {
    condition     = local.config.replicas == 3
    error_message = "Prod environment should have 3 replicas."
  }
}

# ---------------------------------------------------------------------------
# Run 6: Cost center validation
# ---------------------------------------------------------------------------

run "cost_center_validation" {
  command = plan

  variables {
    cost_center = "CC-1234"
  }

  assert {
    condition     = var.cost_center == "CC-1234"
    error_message = "Cost center should be CC-1234."
  }
}

# ---------------------------------------------------------------------------
# Run 7: S3 bucket versioning and encryption enabled
# ---------------------------------------------------------------------------

run "aws_s3_security" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.shared.versioning_configuration[0].status == "Enabled"
    error_message = "S3 bucket versioning should be enabled."
  }

  assert {
    condition     = one([for r in aws_s3_bucket_server_side_encryption_configuration.shared.rule : r.apply_server_side_encryption_by_default[0].sse_algorithm]) == "AES256"
    error_message = "S3 bucket should use AES256 encryption."
  }
}

# ---------------------------------------------------------------------------
# Run 8: Azure storage account has versioning enabled
# ---------------------------------------------------------------------------

run "azure_storage_security" {
  command = plan

  assert {
    condition     = azurerm_storage_account.main.blob_properties[0].versioning_enabled == true
    error_message = "Azure storage account should have blob versioning enabled."
  }

  assert {
    condition     = azurerm_storage_account.main.account_tier == "Standard"
    error_message = "Azure storage account should use Standard tier."
  }
}