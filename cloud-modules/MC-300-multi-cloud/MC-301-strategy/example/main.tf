# MC-301: Multi-Cloud Strategy & Design
# Demonstrates: multi-provider configuration, consistent tagging,
# environment-driven sizing, and workload distribution pattern.

terraform {
  required_version = ">= 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Apply common tags to all AWS resources automatically
  default_tags {
    tags = local.common_tags
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

# ---------------------------------------------------------------------------
# Locals: consistent naming and tagging across both clouds
# ---------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Common tags applied to every resource in both clouds
  # This is the foundation of multi-cloud governance
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Team        = var.team_name
    CostCenter  = var.cost_center
    ManagedBy   = "Terraform"
  }

  # Resolve environment-specific sizing from the variable map
  # Pattern: use var.environment as a key into a configuration map
  config = var.environment_config[var.environment]
}

# ---------------------------------------------------------------------------
# AWS: VPC and networking foundation
# ---------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name  = "${local.name_prefix}-vpc"
    Cloud = "AWS"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name  = "${local.name_prefix}-public-subnet"
    Cloud = "AWS"
    Tier  = "public"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name  = "${local.name_prefix}-igw"
    Cloud = "AWS"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name  = "${local.name_prefix}-public-rt"
    Cloud = "AWS"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# AWS: S3 bucket for shared storage (workload distribution pattern)
# AWS is chosen here for its mature S3 ecosystem
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "shared" {
  bucket = "${local.name_prefix}-shared-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "${local.name_prefix}-shared"
    Cloud   = "AWS"
    Purpose = "shared-storage"
  }
}

resource "aws_s3_bucket_versioning" "shared" {
  bucket = aws_s3_bucket.shared.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "shared" {
  bucket = aws_s3_bucket.shared.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Data source: current AWS account identity
data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# Azure: Resource group and virtual network
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.azure_region

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_virtual_network" "main" {
  name                = "${local.name_prefix}-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_subnet" "public" {
  name                 = "${local.name_prefix}-public-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.1.0/24"]
}

# ---------------------------------------------------------------------------
# Azure: Storage account (demonstrates parallel resource creation)
# Azure Blob Storage used here for Azure-native workloads
# ---------------------------------------------------------------------------

resource "azurerm_storage_account" "main" {
  name                     = replace("${local.name_prefix}sa", "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }

  tags = merge(local.common_tags, {
    Cloud   = "Azure"
    Purpose = "app-storage"
  })
}