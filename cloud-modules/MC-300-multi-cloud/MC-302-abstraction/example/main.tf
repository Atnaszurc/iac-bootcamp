# MC-302: Provider Abstraction Patterns
# Demonstrates: t-shirt size abstraction, conditional resource creation,
# interface pattern (consistent inputs/outputs), and factory pattern.
#
# Key concept: both AWS and Azure resources are defined in the same file.
# count = var.cloud == "aws" ? 1 : 0  controls which cloud is active.
# Outputs are normalized so consumers don't need cloud-specific logic.

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
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

# ---------------------------------------------------------------------------
# Locals: t-shirt size → cloud-specific instance type mapping
# This is the "abstraction layer" - consumers use small/medium/large
# and the module resolves the cloud-specific type internally.
# ---------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })

  # Size mapping: abstract t-shirt sizes to cloud-specific instance types
  # Pattern: locals map[cloud][size] = instance_type
  size_map = {
    aws = {
      small  = "t3.micro"
      medium = "t3.small"
      large  = "t3.medium"
    }
    azure = {
      small  = "Standard_B1s"
      medium = "Standard_B2s"
      large  = "Standard_D2s_v3"
    }
  }

  # Resolved instance types for each cloud based on var.vm_size
  aws_instance_type = local.size_map["aws"][var.vm_size]
  azure_vm_size     = local.size_map["azure"][var.vm_size]
}

# ---------------------------------------------------------------------------
# AWS networking (always created - both clouds run in parallel in this example)
# ---------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name  = "${local.name_prefix}-vpc"
    Cloud = "AWS"
  })
}

resource "aws_subnet" "web" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = merge(local.common_tags, {
    Name  = "${local.name_prefix}-web-subnet"
    Cloud = "AWS"
  })
}

# AWS provider v6: inline ingress/egress blocks in aws_security_group are deprecated.
# Modern code uses aws_vpc_security_group_ingress_rule / aws_vpc_security_group_egress_rule.
# Inline rules still work in v6 but will be removed in a future major version.
resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name  = "${local.name_prefix}-web-sg"
    Cloud = "AWS"
  })
}

# AWS key pair for SSH access
resource "aws_key_pair" "web" {
  key_name   = "${local.name_prefix}-key"
  public_key = var.aws_public_key

  tags = merge(local.common_tags, {
    Cloud = "AWS"
  })
}

# AWS EC2 instance - uses abstracted instance type
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = local.aws_instance_type  # Resolved from t-shirt size
  subnet_id              = aws_subnet.web.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.web.key_name

  tags = merge(local.common_tags, {
    Name  = "${local.name_prefix}-aws-web"
    Cloud = "AWS"
    Size  = var.vm_size  # Store abstract size as tag for reference
  })
}

# Data source: latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------------------
# Azure networking (always created - both clouds run in parallel)
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

resource "azurerm_subnet" "web" {
  name                 = "${local.name_prefix}-web-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_network_security_group" "web" {
  name                = "${local.name_prefix}-web-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow HTTPS inbound"
  }

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_network_interface" "web" {
  name                = "${local.name_prefix}-web-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

# Azure Linux VM - uses abstracted VM size
resource "azurerm_linux_virtual_machine" "web" {
  name                = "${local.name_prefix}-azure-web"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = local.azure_vm_size  # Resolved from t-shirt size
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.web.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.azure_admin_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = merge(local.common_tags, {
    Cloud = "Azure"
    Size  = var.vm_size  # Store abstract size as tag for reference
  })
}