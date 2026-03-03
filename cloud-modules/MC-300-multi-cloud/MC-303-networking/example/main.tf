# MC-303: Cross-Cloud Networking
# Demonstrates: VPN gateway setup, cross-cloud security groups/NSGs,
# private DNS zones, and Route53/Azure DNS resolver configuration.
#
# NOTE: Azure VPN Gateway provisioning takes 30-45 minutes in real deployments.
# This example shows the complete configuration for learning purposes.
# The mock_provider tests validate the configuration without real cloud access.

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
# Locals
# ---------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ===========================================================================
# AWS NETWORKING
# ===========================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name  = "${local.name_prefix}-vpc"
    Cloud = "AWS"
  })
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.aws_private_subnet_a_cidr
  availability_zone = "${var.aws_region}a"

  tags = merge(local.common_tags, {
    Name  = "${local.name_prefix}-private-a"
    Cloud = "AWS"
    Tier  = "private"
  })
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.aws_private_subnet_b_cidr
  availability_zone = "${var.aws_region}b"

  tags = merge(local.common_tags, {
    Name  = "${local.name_prefix}-private-b"
    Cloud = "AWS"
    Tier  = "private"
  })
}

# ---------------------------------------------------------------------------
# AWS VPN Gateway
# ---------------------------------------------------------------------------

resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name  = "${local.name_prefix}-vpn-gw"
    Cloud = "AWS"
  })
}

# Customer Gateway represents the Azure VPN endpoint
# ip_address is set to a placeholder; in real deployments this would be
# the Azure VPN Gateway public IP (azurerm_public_ip.vpn_gw.ip_address)
resource "aws_customer_gateway" "azure" {
  bgp_asn    = var.azure_bgp_asn
  ip_address = "203.0.113.1" # Placeholder - use Azure VPN GW public IP in production
  type       = "ipsec.1"

  tags = merge(local.common_tags, {
    Name  = "${local.name_prefix}-azure-cgw"
    Cloud = "AWS"
  })
}

resource "aws_vpn_connection" "to_azure" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.azure.id
  type                = "ipsec.1"
  static_routes_only  = false # Use BGP for dynamic routing

  tags = merge(local.common_tags, {
    Name  = "${local.name_prefix}-to-azure"
    Cloud = "AWS"
  })
}

# Propagate VPN routes to private route tables
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name  = "${local.name_prefix}-private-rt"
    Cloud = "AWS"
  })
}

resource "aws_vpn_gateway_route_propagation" "private" {
  vpn_gateway_id = aws_vpn_gateway.main.id
  route_table_id = aws_route_table.private.id
}

# ---------------------------------------------------------------------------
# AWS Security Group: allow cross-cloud traffic from Azure VNet
# ---------------------------------------------------------------------------

# AWS provider v6: inline ingress/egress blocks in aws_security_group are deprecated.
# Modern code uses aws_vpc_security_group_ingress_rule / aws_vpc_security_group_egress_rule.
# Inline rules still work in v6 but will be removed in a future major version.
resource "aws_security_group" "cross_cloud" {
  name        = "${local.name_prefix}-cross-cloud-sg"
  description = "Allow traffic from Azure VNet over VPN"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.azure_vnet_cidr]
    description = "HTTPS from Azure VNet"
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.azure_vnet_cidr]
    description = "DNS from Azure VNet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(local.common_tags, {
    Name  = "${local.name_prefix}-cross-cloud-sg"
    Cloud = "AWS"
  })
}

# ---------------------------------------------------------------------------
# AWS Route53: private DNS zone for aws.internal
# ---------------------------------------------------------------------------

resource "aws_route53_zone" "private" {
  name = "aws.internal"

  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = merge(local.common_tags, {
    Cloud = "AWS"
  })
}

# ===========================================================================
# AZURE NETWORKING
# ===========================================================================

resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.azure_region

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_virtual_network" "main" {
  name                = "${local.name_prefix}-vnet"
  address_space       = [var.azure_vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_subnet" "app" {
  name                 = "${local.name_prefix}-app-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.azure_app_subnet_cidr]
}

# GatewaySubnet: Azure requires this exact name for VPN gateway deployment
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet" # Must be exactly "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.azure_gateway_subnet_cidr]
}

# DNS resolver subnets (delegated to Microsoft.Network/dnsResolvers)
resource "azurerm_subnet" "dns_inbound" {
  name                 = "${local.name_prefix}-dns-inbound"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.azure_dns_inbound_subnet_cidr]

  delegation {
    name = "dns-resolver-inbound"
    service_delegation {
      name    = "Microsoft.Network/dnsResolvers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "dns_outbound" {
  name                 = "${local.name_prefix}-dns-outbound"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.azure_dns_outbound_subnet_cidr]

  delegation {
    name = "dns-resolver-outbound"
    service_delegation {
      name    = "Microsoft.Network/dnsResolvers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# ---------------------------------------------------------------------------
# Azure VPN Gateway
# ---------------------------------------------------------------------------

resource "azurerm_public_ip" "vpn_gw" {
  name                = "${local.name_prefix}-vpn-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_virtual_network_gateway" "main" {
  name                = "${local.name_prefix}-vpn-gw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  enable_bgp          = true

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gw.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  bgp_settings {
    asn = var.azure_bgp_asn
  }

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

# Local Network Gateway represents the AWS VPN endpoint
resource "azurerm_local_network_gateway" "aws" {
  name                = "${local.name_prefix}-aws-lng"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  gateway_address     = aws_vpn_connection.to_azure.tunnel1_address

  address_space = [var.aws_vpc_cidr]

  bgp_settings {
    asn                 = var.aws_bgp_asn
    bgp_peering_address = "169.254.21.1"
  }

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_virtual_network_gateway_connection" "to_aws" {
  name                = "${local.name_prefix}-to-aws"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws.id

  shared_key = aws_vpn_connection.to_azure.tunnel1_preshared_key

  enable_bgp = true

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

# ---------------------------------------------------------------------------
# Azure NSG: allow cross-cloud traffic from AWS VPC
# ---------------------------------------------------------------------------

resource "azurerm_network_security_group" "cross_cloud" {
  name                = "${local.name_prefix}-cross-cloud-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowHTTPSFromAWS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.aws_vpc_cidr
    destination_address_prefix = "*"
    description                = "Allow HTTPS from AWS VPC over VPN"
  }

  security_rule {
    name                       = "AllowDNSFromAWS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = var.aws_vpc_cidr
    destination_address_prefix = "*"
    description                = "Allow DNS queries from AWS"
  }

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

# ---------------------------------------------------------------------------
# Azure Private DNS Zone for azure.internal
# ---------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "main" {
  name                = "azure.internal"
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = "${local.name_prefix}-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = true # Auto-register VM hostnames

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}