# MC-302: Provider Abstraction Patterns - Tests
# Uses mock_provider for both AWS and Azure (no credentials required)
# Key tests: t-shirt size mapping, normalized outputs, interface pattern
# Requires Terraform >= 1.7.0

mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id           = "ami-0abcdef1234567890"
      name         = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20240101"
      owner_id     = "099720109477"
      architecture = "x86_64"
    }
  }
}

mock_provider "azurerm" {}

# ---------------------------------------------------------------------------
# Run 1: Default small size maps to correct instance types
# ---------------------------------------------------------------------------

run "small_size_mapping" {
  command = plan

  assert {
    condition     = local.aws_instance_type == "t3.micro"
    error_message = "Small size should map to t3.micro on AWS."
  }

  assert {
    condition     = local.azure_vm_size == "Standard_B1s"
    error_message = "Small size should map to Standard_B1s on Azure."
  }

  assert {
    condition     = var.vm_size == "small"
    error_message = "Default VM size should be 'small'."
  }
}

# ---------------------------------------------------------------------------
# Run 2: Medium size maps to correct instance types
# ---------------------------------------------------------------------------

run "medium_size_mapping" {
  command = plan

  variables {
    vm_size = "medium"
  }

  assert {
    condition     = local.aws_instance_type == "t3.small"
    error_message = "Medium size should map to t3.small on AWS."
  }

  assert {
    condition     = local.azure_vm_size == "Standard_B2s"
    error_message = "Medium size should map to Standard_B2s on Azure."
  }
}

# ---------------------------------------------------------------------------
# Run 3: Large size maps to correct instance types
# ---------------------------------------------------------------------------

run "large_size_mapping" {
  command = plan

  variables {
    vm_size = "large"
  }

  assert {
    condition     = local.aws_instance_type == "t3.medium"
    error_message = "Large size should map to t3.medium on AWS."
  }

  assert {
    condition     = local.azure_vm_size == "Standard_D2s_v3"
    error_message = "Large size should map to Standard_D2s_v3 on Azure."
  }
}

# ---------------------------------------------------------------------------
# Run 4: AWS instance uses the resolved instance type
# ---------------------------------------------------------------------------

run "aws_instance_uses_abstracted_type" {
  command = plan

  variables {
    vm_size = "medium"
  }

  assert {
    condition     = aws_instance.web.instance_type == "t3.small"
    error_message = "AWS instance should use t3.small for medium size."
  }

  assert {
    condition     = aws_instance.web.tags["Size"] == "medium"
    error_message = "AWS instance tag 'Size' should reflect abstract size 'medium'."
  }
}

# ---------------------------------------------------------------------------
# Run 5: Azure VM uses the resolved VM size
# ---------------------------------------------------------------------------

run "azure_vm_uses_abstracted_size" {
  command = plan

  variables {
    vm_size = "large"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.web.size == "Standard_D2s_v3"
    error_message = "Azure VM should use Standard_D2s_v3 for large size."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.web.tags["Size"] == "large"
    error_message = "Azure VM tag 'Size' should reflect abstract size 'large'."
  }
}

# ---------------------------------------------------------------------------
# Run 6: Common tags applied to both clouds
# ---------------------------------------------------------------------------

run "common_tags_both_clouds" {
  command = plan

  variables {
    project_name = "abstraction-test"
    environment  = "staging"
  }

  assert {
    condition     = aws_vpc.main.tags["Project"] == "abstraction-test"
    error_message = "AWS VPC should have Project tag."
  }

  assert {
    condition     = aws_vpc.main.tags["Cloud"] == "AWS"
    error_message = "AWS VPC should have Cloud=AWS tag."
  }

  assert {
    condition     = azurerm_virtual_network.main.tags["Project"] == "abstraction-test"
    error_message = "Azure VNet should have Project tag."
  }

  assert {
    condition     = azurerm_virtual_network.main.tags["Cloud"] == "Azure"
    error_message = "Azure VNet should have Cloud=Azure tag."
  }
}

# ---------------------------------------------------------------------------
# Run 7: Non-overlapping CIDR blocks (critical for multi-cloud)
# ---------------------------------------------------------------------------

run "non_overlapping_cidrs" {
  command = plan

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "AWS VPC CIDR should be 10.0.0.0/16."
  }

  assert {
    condition     = tolist(azurerm_virtual_network.main.address_space)[0] == "10.1.0.0/16"
    error_message = "Azure VNet CIDR should be 10.1.0.0/16 (non-overlapping with AWS)."
  }

  # Verify the two CIDRs are different (no overlap)
  assert {
    condition     = aws_vpc.main.cidr_block != tolist(azurerm_virtual_network.main.address_space)[0]
    error_message = "AWS and Azure CIDR blocks must not overlap."
  }
}

# ---------------------------------------------------------------------------
# Run 8: Size map contains all required entries
# ---------------------------------------------------------------------------

run "size_map_completeness" {
  command = plan

  assert {
    condition     = length(local.size_map["aws"]) == 3
    error_message = "AWS size map should have 3 entries (small, medium, large)."
  }

  assert {
    condition     = length(local.size_map["azure"]) == 3
    error_message = "Azure size map should have 3 entries (small, medium, large)."
  }

  assert {
    condition     = local.size_map["aws"]["small"] == "t3.micro"
    error_message = "AWS small should be t3.micro."
  }

  assert {
    condition     = local.size_map["azure"]["small"] == "Standard_B1s"
    error_message = "Azure small should be Standard_B1s."
  }
}